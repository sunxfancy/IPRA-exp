SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra3.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra3.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra3.bench

sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra3.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra3.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra3.regprof3
