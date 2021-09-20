#!/bin/bash
#
#
#  PARAMETERS : $1 = Redis RELEASES DIRECTORY


current_directory=$(pwd);
cd ..;

for  release in   redis-5.0.3 #redis-5.0.3 redis-5.0.4 redis-5.0.10 redis-6.0.5
do  
    # cd $1/$release/src;
    # # sudo make install;
    # echo $(pwd);
    # extract-bc redis-server;
    # cd ../../..;
    cd Static_Output;
    sudo mkdir -p LoadAfter/$release;
    cd LoadAfter;
    sudo chmod a+rwx $release;
   

    # sudo mkdir -p StoreAfter/$release;
    # cd StoreAfter;
    # sudo chmod a+rwx $release;
    # cd ..;

    # sudo mkdir -p NopAfter/$release;
    # cd NopAfter;
    # sudo chmod a+rwx $release;

    # sudo mkdir -p LoadAndStoreAfter/$release;
    # cd LoadAndStoreAfter;
    # sudo chmod a+rwx $release;

    # sudo mkdir -p WithBranch/$release;
    # cd WithBranch;
    # sudo chmod a+rwx $release;

    cd ../..;
    for i in  2 #4 8
    do
        cd Static_Output;
        sudo mkdir -p LoadAfter/$release/$i;
        cd LoadAfter/$release;
        sudo chmod a+rwx $i;
        

        # sudo mkdir -p StoreAfter/$release/$i;
        # cd StoreAfter/$release;
        # sudo chmod a+rwx $i;
        # cd ../..;


        # sudo mkdir -p LoadAndStoreAfter/$release/$i;
        # cd LoadAndStoreAfter/$release;
        # sudo chmod a+rwx $i;
    

        # sudo mkdir -p NopAfter/$release/$i;
        # cd NopAfter/$release;
        # sudo chmod a+rwx $i;

        # sudo mkdir -p  WithBranch/$release/$i;
        # cd  WithBranch/$release;
        # sudo chmod a+rwx $i;
        cd ../../..;
       


        cd $1/$release/src;
          afterloadFile=/proj/proxyweb-PG0/adona/Redis/Static_Output/LoadAfter/$release/$i; 
        #   afterstoreFile=/proj/proxyweb-PG0/adona/Redis/Static_Output/StoreAfter/$release/$i; 
       #  afternopFile=/proj/proxyweb-PG0/adona/Redis/Static_Output/NopAfter/$release/$i; 
        #afterBothLoadAndStore=/proj/proxyweb-PG0/adona/Redis/Static_Output/LoadAndStoreAfter/$release/$i; 
        #   afterBranchFile=/proj/proxyweb-PG0/adona/Redis/Static_Output/WithBranch/$release/$i;

          load=$i;store=0;nop=0; llc redis-server.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterloadFile} -o RedisLoadAfter_$i.o -filetype=obj;
        #load=0;store=$i;nop=0; llc redis-server.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterstoreFile} -o RedisStoreAfter_$i.o -filetype=obj;
        # load=$i;store=$i;nop=1; llc redis-server.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afternopFile} -o RedisdNopAfter_$i.o -filetype=obj;
        
        # load=$i;store=$i;nop=0; llc redis-server.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterBothLoadAndStore} -o RedisLoadAndStoreAfter_$i.o -filetype=obj
        #  afterBranchFile=/proj/proxyweb-PG0/adona/output/after-emit-with-branch/$release;load=1;store=1;nop=0;branch=1; llc redis-server.bc --enable-emit-pass-with-branch-i --emit-load-ratio-i=${load} --emit-store-ratio-i=${store} --emit-only-nop-i=${nop} --emit-only-branch-i=1 --branched-extract-info-path=${afterBranchFile} -o RedisEmitWithBranchAfter.o -filetype=obj
        cd ../../..;
    done
done 