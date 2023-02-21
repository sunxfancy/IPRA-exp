SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

function run() {
    if [[ $LOCAL_BENCH == "1" ]]; then 
        bash benchmarks/hpcc-$1.sh pgo-full $2
        bash benchmarks/hpcc-$1.sh pgo-full-fdoipra $2
        bash benchmarks/hpcc-$1.sh pgo-full-fdoipra2 $2
        bash benchmarks/hpcc-$1.sh pgo-full-fdoipra3 $2
        bash benchmarks/hpcc-$1.sh pgo-full-bfdoipra $2
        bash benchmarks/hpcc-$1.sh pgo-full-bfdoipra2 $2
        bash benchmarks/hpcc-$1.sh pgo-full-bfdoipra3 $2
        bash benchmarks/hpcc-$1.sh pgo-full-ipra $2
        bash benchmarks/hpcc-$1.sh pgo-full-fdoipra4 $2
        bash benchmarks/hpcc-$1.sh pgo-full-fdoipra5 $2
        bash benchmarks/hpcc-$1.sh pgo-full-fdoipra6 $2
        bash benchmarks/hpcc-$1.sh pgo-full-bfdoipra4 $2
        bash benchmarks/hpcc-$1.sh pgo-full-bfdoipra5 $2
        bash benchmarks/hpcc-$1.sh pgo-full-bfdoipra6 $2
    else 
        sbatch benchmarks/hpcc-$1.sh pgo-full $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra2 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra3 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra2 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra3 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-ipra $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra4 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra5 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra6 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra4 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra5 $2
        sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra6 $2
    fi
}

function build() {
    run clang
    run mysql
    run gcc
    run leveldb
}

function bench_each() {
    echo sbatch --parsable benchmarks/bench.sh $1
    job_id=$(sbatch --parsable benchmarks/bench.sh $1)
    host=`scontrol show job $job_id | grep ' NodeList' | awk -F'=' '{print $2}'`
    until [ "$host" != "(null)" ]
    do
        echo "Waiting for the job executed ..."
        host=`scontrol show job $job_id | grep ' NodeList' | awk -F'=' '{print $2}'`
        sleep 3
    done
    echo sbatch --parsable --dependency=after:${job_id} -w $host benchmarks/bench.sh $1
    sbatch --parsable --dependency=after:${job_id} -w $host benchmarks/bench.sh $1
}


function bench() {
    bench_each leveldb
    bench_each gcc
    bench_each mysql
    bench_each clang
}

function regprof1() {
    run clang regprof1
    run mysql regprof1
    run gcc regprof1
    run leveldb regprof1
} 

function regprof2() {
    run clang regprof2
    run mysql regprof2
    run gcc regprof2
    run leveldb regprof2
}

function regprof3() {
    run clang regprof3
    run mysql regprof3
    run gcc regprof3
    run leveldb regprof3
}

function all() {
    build
    # regprof1
    # regprof2
    regprof3
}

"$@"
