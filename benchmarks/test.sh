SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sbatch benchmarks/hpcc-clang.sh pgo-full
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra2 regprof3
sbatch benchmarks/hpcc-leveldb.sh pgo-full-fdoipra3 regprof3
