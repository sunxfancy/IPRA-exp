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

function bench() {
    sbatch benchmarks/bench.sh leveldb
    sbatch benchmarks/bench.sh gcc
    sbatch benchmarks/bench.sh mysql
    sbatch benchmarks/bench.sh clang
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
