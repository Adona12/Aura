//===-- X86FixupBWInsts.cpp - Fixup Byte or Word instructions -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// This file defines the pass that looks through the machine instructions
/// late in the compilation, and finds byte or word instructions that
/// can be profitably replaced with 32 bit instructions that give equivalent
/// results for the bits of the results that are used. There are two possible
/// reasons to do this.
///
/// One reason is to avoid false-dependences on the upper portions
/// of the registers.  Only instructions that have a destination register
/// which is not in any of the source registers can be affected by this.
/// Any instruction where one of the source registers is also the destination
/// register is unaffected, because it has a true dependence on the source
/// register already.  So, this consideration primarily affects load
/// instructions and register-to-register moves.  It would
/// seem like cmov(s) would also be affected, but because of the way cmov is
/// really implemented by most machines as reading both the destination and
/// and source registers, and then "merging" the two based on a condition,
/// it really already should be considered as having a true dependence on the
/// destination register as well.
///
/// The other reason to do this is for potential code size savings.  Word
/// operations need an extra override byte compared to their 32 bit
/// versions. So this can convert many word operations to their larger
/// size, saving a byte in encoding. This could introduce partial register
/// dependences where none existed however.  As an example take:
///   orw  ax, $0x1000
///   addw ax, $3
/// now if this were to get transformed into
///   orw  ax, $1000
///   addl eax, $3
/// because the addl encodes shorter than the addw, this would introduce
/// a use of a register that was only partially written earlier.  On older
/// Intel processors this can be quite a performance penalty, so this should
/// probably only be done when it can be proven that a new partial dependence
/// wouldn't be created, or when your know a newer processor is being
/// targeted, or when optimizing for minimum code size.
///
//===----------------------------------------------------------------------===//

#include "X86.h"
#include "X86InstrInfo.h"
#include "X86Subtarget.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/LivePhysRegs.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineLoopInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <unordered_set>
#include <cstring>
#include <iostream>
#include <fstream>
#include <map>

using namespace llvm;
using namespace std;

static cl::opt<bool>
    EnableEmitPassWithExtractInfo("enable-emit-pass-with-extract-info",
                 cl::desc("Whether to enable instruction emit pass with extract info pass or not"),
                 cl::init(false), cl::NotHidden);
// Option to allow this optimization pass to have fine-grained control.
static cl::opt<int>
     EmitAndExtractSameLoadInstsRatio("emit-and-extract-same-load-insts-ratio",
                 cl::desc("The ratio of code-bloating through cloning load instructions"),
                 cl::init(0), cl::NotHidden);
static cl::opt<int>
    EmitAndExtractSameStoreInstsRatio("emit-and-extract-same-store-insts-ratio",
                 cl::desc("The ratio of code-bloating through cloning store instructions"),
                 cl::init(0), cl::NotHidden);
static cl::opt<bool>
     EmitAndExtractNop("emit-and-extract-nop",
                 cl::desc("Whether inserting nop during code-bloating or not"),
                 cl::init(false), cl::NotHidden);
static cl::opt<int>
     EmitAndExtractInstCount("emit-and-extract-inst-count",
                 cl::desc("debug purposes"),
                 cl::init(0), cl::NotHidden);

static cl::opt<char*>
     EmitAndExtractExclude("emit-and-extract-exclude",
                 cl::desc("debug purposes"),
         cl::init(getenv("EMIT_EXCLUDE")), cl::NotHidden);

cl::opt<string> EmitPassWithExtractInfoPath("emit-pass-with-extract-info-path",
    cl::desc("Directory path to the extracted stats in extract info pass"),
    cl::value_desc("filename"), cl::init("."));

namespace {
class EmitPassWithExtractInfo: public MachineFunctionPass  {
public:
  static char ID;
  EmitPassWithExtractInfo() :
      MachineFunctionPass(ID) {
    initializeEmitPassWithExtractInfoPass(*PassRegistry::getPassRegistry());
  }
  ~EmitPassWithExtractInfo() {
  if (EnableEmitPassWithExtractInfo) {
      string OutputFilename = EmitPassWithExtractInfoPath + "/summaryStatBasicBlocksHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      std::ofstream fouts(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float function = 0;
        float bb = 0;
        for (auto &elem : BBPerFuncHistogram) {
          function += elem.second;
          bb += elem.first;
          fouts << elem.first << ", " << elem.second << "\n";
          
        }
        fouts <<"avg"<<", "<<(bb/function)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryInstPerBBHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float instructions = 0;
        float bb = 0;
        for (auto &elem : GlobalInstPerBBHistogram) {
          fouts << elem.first << ", " << elem.second << "\n";
          instructions += elem.first;
          bb += elem.second;
        }
        fouts <<"avg"<<", "<<(instructions/bb)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryStorePerBBHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float store = 0;
        float bb = 0;
        for (auto &elem : GlobalStorePerBBHistogram) {
          fouts << elem.first << ", " << elem.second << "\n";
          store += elem.first;
          bb += elem.second;
        }
        fouts <<"avg"<<", "<<(store/bb)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryLoadPerBBHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float load = 0;
        float bb = 0;
        for (auto &elem : GlobalLoadPerBBHistogram) {
          fouts << elem.first << ", " << elem.second << "\n";

        load += elem.first;
          bb += elem.second;
        }
        fouts <<"avg"<<", "<<(load/bb)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryOtherPerBBHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float other = 0;
        float bb = 0;
        for (auto &elem : GlobalOtherPerBBHistogram) {
          fouts << elem.first << ", " << elem.second << "\n";
          other += elem.first;
          bb += elem.second;
        }
        fouts <<"avg"<<", "<<(other/bb)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryStorePerFunctionHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float store = 0;
        float function = 0;
        for (auto &elem : GlobalstorePerFunctionHistogram) {
          fouts << elem.first << ", " << elem.second << "\n";
          store += elem.first;
          function += elem.second;
        }
        fouts <<"avg"<<", "<<(store/function)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryLoadPerFunctionHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float load = 0;
        float function = 0;
        for (auto &elem : GloballoadPerFunctionHistogram) {
          load += elem.first;
          function += elem.second;
          fouts << elem.first << ", " << elem.second << "\n";
        }
        fouts <<"avg"<<", "<<(load/function)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryInstructionsPerFunctionHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float instructions = 0;
        float function = 0;
        for (auto &elem : GlobalInstPerFunctionHistogram) {
          instructions += elem.first;
          function += elem.second;
          fouts << elem.first << ", " << elem.second << "\n";
        }
        fouts <<"avg"<<", "<<(instructions/function)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryOtherInstsPerFunctionHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        float other = 0;
        float function = 0;
        for (auto &elem : GlobalOtherPerFunctionHistogram) {
          other += elem.first;
          function += elem.second;
          fouts << elem.first << ", " << elem.second << "\n";
        }
        fouts <<"avg"<<", "<<(other/function)<<"\n";
        fouts.close();
      }
      OutputFilename = EmitPassWithExtractInfoPath + "/summaryStatFunctionHistogram.csv";
      outs() << "Writing to " << OutputFilename << "\n";
      fouts.open(OutputFilename.c_str());
      if (!fouts.is_open()) {
        outs() << "Bad path\n";
      } else {
        fouts <<"Func"<<", "<<numFunctions<<"\n";
        fouts.close();
      }
    }
  }
  std::map<int,int> BBPerFuncHistogram;
  std::map<int,int> GlobalInstPerBBHistogram;
  std::map<int,int> GlobalStorePerBBHistogram;
  std::map<int,int> GlobalLoadPerBBHistogram;
  std::map<int,int> GlobalOtherPerBBHistogram;
  std::map<int,int> GlobalInstPerFunctionHistogram;
  std::map<int,int> GlobalstorePerFunctionHistogram;
  std::map<int,int> GloballoadPerFunctionHistogram;
  std::map<int,int> GlobalOtherPerFunctionHistogram;
  int numFunctions = 0;
  void getAnalysisUsage(AnalysisUsage &AU) const override {


    MachineFunctionPass::getAnalysisUsage(AU);
  }

    /// This create and returns Noop instruction
  MachineInstr* tryNoop(MachineInstr *MI) const {
    MachineInstrBuilder MIB =
        BuildMI(*MF, MI->getDebugLoc(), TII->get(X86::NOOP));

    return MIB;
  }

    /// This clones the given instruction
  MachineInstr* tryClone(const MachineInstr *MI, MachineFunction &MF) const {
    MachineInstr * NewMI = MF.CloneMachineInstr(MI);
    return NewMI;
  }

  bool isPushPop(const MachineInstr* MI) const {
    switch (MI->getOpcode()) {
    case X86::PUSH32i8:
    case X86::PUSH32r:
    case X86::PUSH32rmm:
    case X86::PUSH32rmr:
    case X86::PUSHi32:
    case X86::PUSH64i8:
    case X86::PUSH64r:
    case X86::PUSH64rmm:
    case X86::PUSH64rmr:
    case X86::PUSH64i32:
    case X86::POP32r:
    case X86::POP64r:
      return true;
    default:
      return false;
    }
  }
  bool isOperandInfo48Inst(MachineInstr *MI)const{
    unsigned short opcode = MI->getOpcode();
    if ((opcode == 154)
          ||(opcode == 168)
          ||(opcode == 202)
          ||(opcode == 296)
          ||(opcode == 515)
          ||(opcode == 521)
          ||(opcode == 527)
          ||(opcode == 533)
          ||(opcode == 547)
          ||(opcode == 557)
          ||(opcode == 563)
          ||(opcode == 569)
          ||(opcode == 575)
          ||(opcode == 589)
          ||(opcode == 599)
          ||(opcode == 605)
          ||(opcode == 615)
          ||(opcode == 621)
          ||(opcode == 627)
          ||(opcode == 637)
          ||(opcode == 751)
          ||(opcode == 752)
          ||(opcode == 1113)
          ||(opcode == 1510)
          ||(opcode == 2043)
          ||(opcode == 2731)
          ||(opcode == 2988)
          ||(opcode == 15361)
          ||(opcode == 15400)){
      return true;
    }
    return false;
  }

  bool isDestructiveLoadOrStore(MachineInstr *MI) const {
    bool f = false;
//    if((MI->getOpcode() == 1085) || (MI->getOpcode() == 1369)){
////    if((MI->getOpcode() == 1085)){
//      return true;
//    }
    std::unordered_set<unsigned int> implicit_def;
    std::unordered_set<unsigned int> implicit;

    for (int i = 0; i < MI->getNumOperands(); i++) {
      if (MI->getOperand(i).isReg()) {

//        if (MI->getOperand(i).isImplicit()) {
          f = true;
//          outs() << "\n !!! isImplicit:\n";
//
//          MI->getOperand(i).dump();
//          outs() << "\n";
//          outs() << "reg:"<< i<<" "<< MI->getOperand(i).getReg()
//              << " isTied:" << MI->getOperand(i).isTied()
//              << " getSubReg:" << MI->getOperand(i).getSubReg()
//              << " readsReg:" << MI->getOperand(i).readsReg()
//              << " isKilled:" << MI->getOperand(i).isKill()
//              << " isdead:" << MI->getOperand(i).isDead()
//              << " isDef:" << MI->getOperand(i).isDef()
//              << "\n";
//        }

        if (MI->getOperand(i).readsReg()
            && MI->getOperand(i).isKill()) {
//          if (f) {
//            MI->dump();
//            outs() << "\n-------------------------\n ";
//          }
          return true;
        }
        if (MI->getOperand(i).isImplicit() && MI->getOperand(i).isDef()) {
          auto it = implicit.find(MI->getOperand(i).getReg());
          if(it == implicit.end()){
            implicit_def.insert(MI->getOperand(i).getReg());
          }
          else{
            return true;
          }
        }else if(MI->getOperand(i).isImplicit() && (!MI->getOperand(i).isDef())){
          auto it = implicit_def.find(MI->getOperand(i).getReg());
          if(it == implicit_def.end()){
            implicit.insert(MI->getOperand(i).getReg());
          }
          else{
            return true;
          }
        }
      }
    }
//    if (f) {
//      MI->dump();
//      outs() << "\n-------------------------\n ";
//    }
    return false;
  }

//
    bool printOperands(MachineInstr *MI, int p)const{
    bool f = false;
//      if((MI->mayStore()|| !MI->mayLoad())) {
//    if (MI->getOpcode() == 840) {
      dbgs() << "~~p:"<<p<<" - Instruction " << TII->getName(MI->getOpcode())
          << " Opcode: " << MI->getOpcode() << "\n";
      MI->dump();
      dbgs() << "\n******************************************************\n\n ";
//    }
    return false;
  }
  bool isIdempotentStore(MachineInstr *MI) const {
    if((!MI->isNotDuplicable())
        && MI->mayStore()
        && !MI->mayLoad()
        && !isPushPop(MI)
        && !MI->isBundled()
        && (!isDestructiveLoadOrStore(MI))
        && (!MI->isCall())
        && (!MI->isBranch())) {
//      if(isDestructiveLoadOrStore(MI)){
//        return false;
//      }
//    if(MI->mayStore() && !MI->mayLoad() && !isPushPop(MI)) {
      return true;
    }
    return false;
  }

  bool isIdempotentLoad(MachineInstr *MI) const {
    if((!MI->isNotDuplicable())
        && MI->mayLoad()
        && !MI->mayStore()
        && !isPushPop(MI)
        && !MI->isBundled()
        && (!isDestructiveLoadOrStore(MI))
        && (!MI->isCall())
        && (!MI->isBranch())) {
      return true;
    }
    return false;
  }

  bool runOnMachineFunction(MachineFunction &MF) override {
    if (!EnableEmitPassWithExtractInfo || skipFunction(MF.getFunction()))
      return false;
    this->MF = &MF;
    TII = MF.getSubtarget<X86Subtarget>().getInstrInfo();
    int basicBlockCount = 0;
    int instructionsPerBasicBlock = 0;
    int storesPerBasicBlock = 0;
    int loadsPerBasicBlock = 0;
    int otherPerBasicBlock = 0;
    int instructionsPerFunction = 0;
    int storesPerFunction = 0;
    int loadesPerFunction = 0;
    int othersPerFunction = 0;

    numFunctions++;
    //int flag = EmitInstCount;
    for (MachineBasicBlock &MBB : MF) {
      if(MBB.empty())
        continue;
      basicBlockCount++;
      instructionsPerBasicBlock = 0;
      storesPerBasicBlock = 0;
      loadsPerBasicBlock = 0;
      otherPerBasicBlock = 0;
      for(auto it = MBB.begin(); it != MBB.end(); it++) {
        instructionsPerBasicBlock++;
        MachineInstr* MI = &(*it);
        if( MI->mayLoad()){
          loadsPerBasicBlock++;
        }
        if(isIdempotentLoad(MI)) {


            for(int i = 0; i < EmitAndExtractSameLoadInstsRatio; i++) {
//            outs() << "clone load instruction " << MI << "opcode "<<MI->getOpcode() <<" in Func " << MF.getName() << "\n";
//            MI->dump();
//            printOperands(MI);
//            outs() << "\n";
            MachineInstr * NewMI = nullptr;
            if(EmitAndExtractNop) {
              printOperands(MI, 1);
              NewMI = tryNoop(MI);
            }
            else {
              printOperands(MI,2);
              NewMI = MF.CloneMachineInstr(MI);
//              if(isDestructiveLoadOrStore(MI)){
//                outs() << "\n";
//                outs() << "destructive load instruction " << MI <<"emmited in Func " << MF.getName() << "\n";
//              }
//              NewMI = &(MF.CloneMachineInstrBundle(MBB, it, *MI));
            }
            MBB.insert(it, NewMI);
            loadsPerBasicBlock++;
            instructionsPerBasicBlock++;
          }
        }
        if( MI->mayStore()){
          storesPerBasicBlock++;
        }
        if(isIdempotentStore(MI)) {
//          if(EmitSameStoreInstsRatio)
//            flag--;
          for(int i = 0; i < EmitAndExtractSameStoreInstsRatio; i++) {
//            outs() << "clone store instruction " << MI << " in Func " << MF.getName() << "\n";
//            MI->dump();
//            outs() << "\n";
            MachineInstr * NewMI = nullptr;
            if(EmitAndExtractNop) {
              printOperands(MI,3);
              NewMI = tryNoop(MI);
            }
            else {
              printOperands(MI,4);
              NewMI = MF.CloneMachineInstr(MI);
            }
            MBB.insert(it, NewMI);
            storesPerBasicBlock++;
            instructionsPerBasicBlock++;
          }
        }
        if(!MI->mayLoadOrStore()){
          otherPerBasicBlock++;
        }
        
      
      }
      storesPerFunction += storesPerBasicBlock;
      loadesPerFunction += loadsPerBasicBlock;
      othersPerFunction += otherPerBasicBlock;
      instructionsPerFunction += instructionsPerBasicBlock;
      GlobalInstPerBBHistogram[instructionsPerBasicBlock]++;
      GlobalStorePerBBHistogram[storesPerBasicBlock]++;
      GlobalLoadPerBBHistogram[loadsPerBasicBlock]++;
      GlobalOtherPerBBHistogram[otherPerBasicBlock]++;
    }
    GlobalstorePerFunctionHistogram[storesPerFunction]++;
    GloballoadPerFunctionHistogram[loadesPerFunction]++;
    GlobalInstPerFunctionHistogram[instructionsPerFunction]++;
    GlobalOtherPerFunctionHistogram[othersPerFunction]++;
    BBPerFuncHistogram[basicBlockCount]++;
    return true;
  }
private:
  MachineFunction *MF;

  /// Machine instruction info used throughout the class.
  const X86InstrInfo *TII;
};
char EmitPassWithExtractInfo::ID = 0;
}

INITIALIZE_PASS(EmitPassWithExtractInfo, "x86-emit-pass-with-extract-info", "X86 Emit pass with extract info", false, false)

FunctionPass *llvm::createX86EmitPassWithExtractInfo() { return new EmitPassWithExtractInfo(); }