import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot as plt
import csv
import numpy as np


releases = [  "1.4.22" , "1.4.30",  "1.5.12" , "1.5.20" , "1.6.9" ]
categories = ["WithBranch" ]# "LoadAfter" ,"StoreAfter"]#, "NopAfter","LoadAndStoreAfter"  ]
values = ["2", "4", "8"]


scategories = ["NumberOfFunctions","BasicBlocksPerFunction","InstructionsperBasicBlock"  ,"LoadInstructionsperBasicBlock"   ,"StoreInstructionsperBasicBlock"     , "otherInstructionsPerBasicBlock",   "InstructionsPerFunction",      "LoadInstructionsPerFunction",'StoreInstructionsPerFunction',"otherInstructionsPerFunction"]
fcategories = ["NumberOfFunctions.csv","BasicBlocksPerFunction.csv","InstructionsperBasicBlock.csv","LoadInstructionsperBasicBlock.csv","StoreInstructionsperBasicBlock.csv","otherInstructionsPerBasicBlock.csv","InstructionsPerFunction.csv", "LoadInstructionsPerFunction.csv" ,"StoreInstructionsPerFunction.csv","otherInstructionsPerFunction.csv" ]

for category in categories:
    index = 0
    categoryDir = "../memcached_output/output/"+category+"/"
    print(matplotlib.__version__)
    for scat in scategories:
        index+=1
        before =[]
        two = []
        four = []
        eight =[]
        withBranch = []
        with open(categoryDir+fcategories[index-1] , "r" ) as fi:
            reader = csv.reader(fi , delimiter=",")
            datas = list(reader)
            for data in datas:
                if(category == "WithBranch"):
                    withBranch.append(float(data[1].strip()))
                else:
                    two.append(float(data[1].strip()))
                    four.append(float(data[2].strip()))
                    eight.append(float(data[3].strip()))
                before.append(float(data[0].strip()))
                
            width=0.2
            x = np.arange(len(releases))
            fig, ax = plt.subplots()
            labelTwo = ''
            labelFour = ''
            labelEight = ''
            if category == "LoadAfter":
                labelTwo = "Load = 2"
                labelFour= "Load = 4"
                labelEight= "Load = 8"
            elif category == "StoreAfter":
                labelTwo = "Store = 2"
                labelFour= "Store = 4"
                labelEight= "Store = 8"
            elif category == "LoadAndStoreAfter":
                labelTwo = "Load = 2,Store = 2"
                labelFour= "Load = 4,Store = 4"
                labelEight= "Load = 8,Store = 8"
            elif category == "NopAfter":
                labelTwo = "Nop = 2"
                labelFour= "Nop = 4"
                labelEight= "Nop = 8"
           
            elif(category == "WithBranch"):
                labelTwo ="Before Pass"
                labelFour = "After pass"

            else:
                labelTwo = "Nop = 2"
                labelFour= "Nop = 4"
                labelEight= "Nop = 8"

                #only for non with branch
            # if(category == "before"):
            #     width = 0.5
            #     rects1 = ax.bar((x)-width,before, width, color="#993366")
            # elif(category != "withBranch"):
            #     rects1 = ax.bar((x - width/2)-width,before, width, color="#365367",label='Before Pass')
            #     rects2 = ax.bar(x - width/2, two, width,color="#FFBAA2", label=labelTwo)
            #     rects3 = ax.bar(x + width/2, four, width,color="#993366", label=labelFour)
            #     rects4 = ax.bar((x + width/2)+width, eight, width,color="#F494AB", label=labelEight)
            
            # only for with branch
            rects2 = ax.bar(x - width/2, before, width,color="#FFBAA2", label=labelTwo)
            rects3 = ax.bar(x + width/2, withBranch, width,color="#993366", label=labelFour)
            
      

            ax.set_title(scat +"  VS version")
            ax.set_xticks(x)
            ax.set_xticklabels(releases)
            ax.legend()
            plt.xlabel("Versions")
            plt.ylabel(scat)

            fig.tight_layout()
            plt.savefig("../memcached_output/output/Graphs/"+category+"/"+scat+".jpg")
                    # plt.show()
        # finished building a graph for a categories of a thread.