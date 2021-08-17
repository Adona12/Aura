#!/bin/bash
# my first script
#
#
#  PARAMETERS : $1 = MEMCACHED RELEASES DIRECTORY


current_directory=$(pwd);

for  release in    memcached-1.4.22
do  
    cd $1/$release;
    sudo make install;
    extract-bc memcached;
    cd ../..;
    cd output;
    # sudo mkdir -p after-load-only/$release;
    # cd after-load-only;
    # sudo chmod a+rwx $release;
    # cd ..;

    sudo mkdir -p after-store-only/$release;
    cd after-store-only;
    sudo chmod a+rwx $release;
    # cd ..;

    # sudo mkdir -p after-nop/$release;
    # cd after-nop;
    # sudo chmod a+rwx $release;

    #  sudo mkdir -p after-both-load-and_store/$release;
    # cd after-both-load-and_store;
    # sudo chmod a+rwx $release;
    cd ../..;

    for i in 8
    do
        cd output;
        # sudo mkdir -p after-load-only/$release/$i;
        # cd after-load-only/$release;
        # sudo chmod a+rwx $i;
        # cd ../..;

        sudo mkdir -p after-store-only/$release/$i;
        cd after-store-only/$release;
        sudo chmod a+rwx $i;
        # cd ../..;


        # sudo mkdir -p after-both-load-and_store/$release/$i;
        # cd after-both-load-and_store/$release;
        # sudo chmod a+rwx $i;
        # cd ../..;

        # sudo mkdir -p after-nop/$release/$i;
        # cd after-nop/$release;
        # sudo chmod a+rwx $i;
        cd ../../..;


        cd $1/$release;
        #  afterloadFile=/proj/proxyweb-PG0/adona/output/after-load-only/$release/$i; 
           afterstoreFile=/proj/proxyweb-PG0/adona/output/after-store-only/$release/$i; 
        #  afternopFile=/proj/proxyweb-PG0/adona/output/after-nop/$release/$i; 
        #  afterBothLoadAndStore==/proj/proxyweb-PG0/adona/output/after-both-load-and_store/$release/$i; 

        #  load=$i;store=0;nop=0; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterloadFile} -o memcachedLoadAfter_$i.o -filetype=obj;
         load=0;store=$i;nop=0; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterstoreFile} -o memcachedStoreAfter_$i.o -filetype=obj;
        #  load=$i;store=$i;nop=1; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afternopFile} -o memcachedNopAfter_$i.o -filetype=obj;
        #  load=$i;store=$i;nop=0; llc memcached.bc --enable-emit-pass-with-extract-info --emit-and-extract-same-load-insts-ratio=${load} --emit-and-extract-same-store-insts-ratio=${store} --emit-and-extract-nop=${nop} --emit-pass-with-extract-info-path=${afterBothLoadAndStore} -o memcachedLoadAndStoreAfter_$i.o -filetype=obj
        cd ../..;
    done
done 
