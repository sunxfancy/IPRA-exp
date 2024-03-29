SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

function run() {
    if [[ $LOCAL_BENCH == "1" ]]; then 
        bash benchmarks/hpcc-$1.sh pgo-thin $2
        bash benchmarks/hpcc-$1.sh pgo-thin-fdoipra $2
        bash benchmarks/hpcc-$1.sh pgo-thin-fdoipra2 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-fdoipra3 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-bfdoipra $2
        bash benchmarks/hpcc-$1.sh pgo-thin-bfdoipra2 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-bfdoipra3 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-ipra $2
        bash benchmarks/hpcc-$1.sh pgo-thin-fdoipra4 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-fdoipra5 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-fdoipra6 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-bfdoipra4 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-bfdoipra5 $2
        bash benchmarks/hpcc-$1.sh pgo-thin-bfdoipra6 $2
    else 
        sbatch benchmarks/hpcc-$1.sh pgo-thin $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-fdoipra $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-fdoipra2 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-fdoipra3 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-bfdoipra $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-bfdoipra2 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-bfdoipra3 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-ipra $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-fdoipra4 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-fdoipra5 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-fdoipra6 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-bfdoipra4 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-bfdoipra5 $2
        sbatch benchmarks/hpcc-$1.sh pgo-thin-bfdoipra6 $2
    fi
}

function build() {
    run clang
    run mysql
    run gcc
    run leveldb
    run mongodb
}

function bench_each() {
    echo sbatch --parsable benchmarks/bench.sh $1
    job_id=`sbatch --parsable benchmarks/bench.sh $1`
    echo $job_id
    host=`scontrol show job $job_id | grep ' NodeList' | awk -F'=' '{print $2}'`
    until [ "$host" != "" ]
    do
        echo "Waiting for the job executed ..."
        host=`scontrol show job $job_id | grep ' NodeList' | awk -F'=' '{print $2}'`
        sleep 3
    done
    echo $host
    echo sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
    job_id=`sbatch --parsable --dependency=after:$job_id -w $host benchmarks/bench.sh $1`
}

function bench() {
    bench_each leveldb
    bench_each gcc
    bench_each mysql
    bench_each clang
    bench_each mongodb
}

function regprof1() {
    run clang regprof1
    run mysql regprof1
    run gcc regprof1
    run leveldb regprof1
    run mongodb regprof1
} 

function regprof2() {
    run clang regprof2
    run mysql regprof2
    run gcc regprof2
    run leveldb regprof2
    run mongodb regprof2
}

function regprof3() {
    run clang regprof3
    run mysql regprof3
    run gcc regprof3
    run leveldb regprof3
    run mongodb regprof3
}

function all() {
    build
    # regprof1
    # regprof2
    regprof3
}

"$@"
