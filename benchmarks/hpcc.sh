SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

function run() {
    sbatch benchmarks/hpcc-$1.sh pgo-full $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra2 $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-fdoipra3 $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra2 $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-bfdoipra3 $2
    sbatch benchmarks/hpcc-$1.sh pgo-full-ipra $2
}

function bench() {
    run clang bench
    run mysql bench
    run gcc bench
    run leveldb bench
}

function regprof3() {
    run clang regprof3
    run mysql regprof3
    run gcc regprof3
    run leveldb regprof3
}

function all() {
    bench
    regprof3
}

"$@"
