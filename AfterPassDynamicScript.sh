#!/bin/bash
# my first script
#
#
#  PARAMETERS : $1 = MEMCACHED RELEASES DIRECTORY
 #              $2 = Thread
current_directory=$(pwd);
CPUSET=1-$2;
# for  release in  memcached-1.5.12 memcached-1.5.20 memcached-1.6.9
# do  
#     cd $1/$release;
#     echo $release; 
#     echo "before";
#     sudo make install;
#     memcached -d -m 1024 -u root -l 127.0.0.1 -p 11211;
# #   -d - to specify that Memcached runs on daemon
# #   -m - to specify the memory by default its 64
# #   -u - to specify that Memcached is going to run as root
# #   -l  - to specify the ip address 
# #   -p  - its used to specify the port which Memcachedis going to run on

#     sudo taskset -apc ${CPUSET} $(pidof memcached)
#     pidof memcached;
#     cd $current_directory;
#     for workload in workloada workloadb workloadc workloadd workloade workloadf
#     do
#          echo  $(pwd);
#          sudo mkdir -p perf_output/before;
#          sudo chmod a+rwx perf_output/before;
#          sudo mkdir -p perf_output/before/$release;
#          sudo chmod a+rwx perf_output/before/$release;
#          sudo mkdir -p perf_output/before/$release/$2;
#          sudo chmod a+rwx perf_output/before/$release/$2;
#          cd YCSB;
#          sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses  --no-big-num -- sudo  ./bin/ycsb load memcached -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &>  ../perf_output/before/$release/$2/${release}_${workload}_$2_load.txt;
#          sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num  -- sudo ./bin/ycsb run memcached -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &> ../perf_output/before/$release/$2/${release}_${workload}_$2_run.txt;
#         cd $current_directory;
#     done
#     killall -9 pid memcached;
# done
for  release in memcached-1.4.22 memcached-1.4.30  memcached-1.5.12 memcached-1.5.20 memcached-1.6.9
do  
    echo $release; 
    echo "after";
    cd $1/$release;
    for i in 2
    do
        sudo mv memcached memcached_before
        sudo mv memcachedLoadAfter_$i memcached;
        sudo make install;
        memcached -d -m 1024 -u root -l 127.0.0.1 -p 11211 -t $2;
        sudo taskset -apc ${CPUSET} $(pidof memcached)
#   -a - Set or retrieve the CPU affinity of all the tasks
#   -p - Operate on an existing PID and do not launch a new task.
#   -c  - to specify a range of CPU's

        pidof memcached;
        cd $current_directory;
        for workload in workloada workloadb workloadc workloadd workloade workloadf
        do
            echo  $(pwd);
            sudo mkdir -p perf_output/after;
            sudo chmod a+rwx perf_output/after;
            sudo mkdir -p perf_output/after_load_only/$release
            sudo chmod a+rwx perf_output/after_load_only/$release;
            sudo mkdir -p perf_output/after_load_only/$release/thread_$2;
            sudo chmod a+rwx perf_output/after_load_only/$release/thread_$2;
            sudo mkdir -p perf_output/after_load_only/$release/thread_$2/load_$i;
            sudo chmod a+rwx perf_output/after_load_only/$release/thread_$2/load_$i;
            cd YCSB;
            sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num -- sudo  ./bin/ycsb load memcached -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &>  ../perf_output/after_load_only/$release/thread_$2/load_$i/${release}_${workload}_thread_$2_num${i}_after_load.txt;
            sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num -- sudo  ./bin/ycsb run memcached  -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &> ../perf_output/after_load_only/$release/thread_$2/load_$i/${release}_${workload}_thread_$2_num${i}_after_run.txt;
            cd $current_directory;
        done
        cd $1/$release;
        sudo mv memcached memcachedLoadAfter_$i;
        sudo mv memcached_before memcached;
        cd $current_directory;
        killall -9 pid memcached;
    done


##################for emit pass with store only
      for i in 2
    do
        sudo mv memcached memcached_before
        sudo mv memcachedStoreAfter_$i memcached;
        sudo make install;
        memcached -d -m 1024 -u root -l 127.0.0.1 -p 11211 -t $2;
        sudo taskset -apc ${CPUSET} $(pidof memcached)
#   -a - Set or retrieve the CPU affinity of all the tasks
#   -p - Operate on an existing PID and do not launch a new task.
#   -c  - to specify a range of CPU's

        pidof memcached;
        cd $current_directory;
        for workload in workloada workloadb workloadc workloadd workloade workloadf
        do
            echo  $(pwd);
            sudo mkdir -p perf_output/after;
            sudo chmod a+rwx perf_output/after;
            sudo mkdir -p perf_output/after_store_only/$release
            sudo chmod a+rwx perf_output/after_store_only/$release;
            sudo mkdir -p perf_output/after_store_only/$release/thread_$2;
            sudo chmod a+rwx perf_output/after_store_only/$release/thread_$2;
            sudo mkdir -p perf_output/after_store_only/$release/thread_$2/load_$i;
            sudo chmod a+rwx perf_output/after_store_only/$release/thread_$2/load_$i;
            cd YCSB;
            sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num -- sudo  ./bin/ycsb load memcached -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &>  ../perf_output/after_load_only/$release/thread_$2/load_$i/${release}_${workload}_thread_$2_num${i}_after_load.txt;
            sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num -- sudo  ./bin/ycsb run memcached  -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &> ../perf_output/after_load_only/$release/thread_$2/load_$i/${release}_${workload}_thread_$2_num${i}_after_run.txt;
            cd $current_directory;
        done
        cd $1/$release;
        sudo mv memcached memcachedStoreAfter_$i;
        sudo mv memcached_before memcached;
        cd $current_directory;
        killall -9 pid memcached;
    done


##################for emit pass with nop only
      for i in 2
    do
        sudo mv memcached memcached_before
        sudo mv memcachedNopAfter_$i memcached;
        sudo make install;
        memcached -d -m 1024 -u root -l 127.0.0.1 -p 11211 -t $2;
        sudo taskset -apc ${CPUSET} $(pidof memcached)
#   -a - Set or retrieve the CPU affinity of all the tasks
#   -p - Operate on an existing PID and do not launch a new task.
#   -c  - to specify a range of CPU's

        pidof memcached;
        cd $current_directory;
        for workload in workloada workloadb workloadc workloadd workloade workloadf
        do
            echo  $(pwd);
            sudo mkdir -p perf_output/after;
            sudo chmod a+rwx perf_output/after;
            sudo mkdir -p perf_output/after_nop/$release
            sudo chmod a+rwx perf_output/after_nop/$release;
            sudo mkdir -p perf_output/after_nop/$release/thread_$2;
            sudo chmod a+rwx perf_output/after_nop/$release/thread_$2;
            sudo mkdir -p perf_output/after_nop/$release/thread_$2/load_$i;
            sudo chmod a+rwx perf_output/after_nop/$release/thread_$2/load_$i;
            cd YCSB;
            sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num -- sudo  ./bin/ycsb load memcached -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &>  ../perf_output/after_load_only/$release/thread_$2/load_$i/${release}_${workload}_thread_$2_num${i}_after_load.txt;
            sudo perf stat -a -C ${CPUSET} -e cycles,branches,branch-misses,branch-loads,branch-load-misses,L1-icache-load-misses --no-big-num -- sudo  ./bin/ycsb run memcached  -threads ${2} -s -P workloads/$workload -p  memcached.hosts=localhost:11211 &> ../perf_output/after_load_only/$release/thread_$2/load_$i/${release}_${workload}_thread_$2_num${i}_after_run.txt;
            cd $current_directory;
        done
        cd $1/$release;
        sudo mv memcached memcachedNopAfter_$i;
        sudo mv memcached_before memcached;
        cd $current_directory;
        killall -9 pid memcached;
    done
done