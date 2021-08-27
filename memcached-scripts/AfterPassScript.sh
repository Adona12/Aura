#!/bin/bash
# my first script
#
#
#  PARAMETERS : $1 = MEMCACHED RELEASES DIRECTORY


current_directory=$(pwd);
cd ..;

for  release in   memcached-1.4.22 memcached-1.4.30 memcached-1.5.12 memcached-1.5.20 memcached-1.6.9
do  
    cd $1/$release;
    # sudo make install;
    echo $(pwd);
    #extract-bc memcached;
    cd ../..;
    cd memcached_output/output;
    # sudo mkdir -p after-load-only/$release;
    # cd after-load-only;
    # sudo chmod a+rwx $release;
    # cd ..;

    # sudo mkdir -p StoreAfter/$release;
    # cd StoreAfter;
    # sudo chmod a+rwx $release;
    # cd ..;

    sudo mkdir -p NopAfter/$release;
    cd NopAfter;
    sudo chmod a+rwx $release;

    # sudo mkdir -p LoadAndStoreAfter/$release;
    # cd LoadAndStoreAfter;
    # sudo chmod a+rwx $release;

    # sudo mkdir -p after-emit-with-branch/$release;
    # cd after-emit-with-branch;
    # sudo chmod a+rwx $release;
    cd ../../..;
    

    # for i in  2 4 8
    # do
    #     echo $(pwd);
    #     cd memcached_output/output;
        # sudo mkdir -p after-load-only/$release/$i;
        # cd after-load-only/$release;
        # sudo chmod a+rwx $i;
        # cd ../..;

        # sudo mkdir -p StoreAfter/$release/$i;
        # cd StoreAfter/$release;
        # sudo chmod a+rwx $i;
        # cd ../..;


        # sudo mkdir -p LoadAndStoreAfter/$release/$i;
        # cd LoadAndStoreAfter/$release;
        # sudo chmod a+rwx $i;
        # cd ../..;

        # sudo mkdir -p NopAfter/$release/$i;
        # cd NopAfter/$release;
        # sudo chmod a+rwx $i;

        # sudo mkdir -p  after-emit-with-branch/$release/$i;
        # cd  after-emit-with-branch/$release;
        # sudo chmod a+rwx $i;
        cd ../../../..;
       


        # cd $1/$release;
        #  afterloadFile=/proj/proxyweb-PG0/adona/output/after-load-only/$release/$i; 
        #   afterstoreFile=/proj/proxyweb-PG0/adona/memcached_output/output/StoreAfter/$release/$i; 
         afternopFile=/proj/proxyweb-PG0/adona/memcached_output/output/NopAfter/$release/$i; 
        #afterBothLoadAndStore=/proj/proxyweb-PG0/adona/memcached_output/output/LoadAndStoreAfter/$release/$i; 
        #   afterBranchFile=/proj/proxyweb-PG0/adona/output/after-emit-with-branch/$release/$i;

        #  load=$i;store=0;nop=0; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterloadFile} -o memcachedLoadAfter_$i.o -filetype=obj;
        #load=0;store=$i;nop=0; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterstoreFile} -o memcachedStoreAfter_$i.o -filetype=obj;
         # load=$i;store=$i;nop=1; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afternopFile} -o memcachedNopAfter_$i.o -filetype=obj;
        
        # load=$i;store=$i;nop=0; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterBothLoadAndStore} -o memcachedLoadAndStoreAfter_$i.o -filetype=obj
          afterBranchFile=/proj/proxyweb-PG0/adona/output/after-emit-with-branch/$release;load=1;store=1;nop=0;branch=1; llc memcached.bc --enable-emit-pass-with-branch-i --emit-load-ratio-i=${load} --emit-store-ratio-i=${store} --emit-only-nop-i=${nop} --emit-only-branch-i=1 --branched-extract-info-path=${afterBranchFile} -o memcachedEmitWithBranchAfter.o -filetype=obj
        cd ../..;
   # done
done 