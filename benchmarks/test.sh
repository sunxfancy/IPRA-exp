SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra.regprof3
