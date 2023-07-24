SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sbatch benchmarks/hpcc-clang.sh pgo-thin
sbatch benchmarks/hpcc-mysql.sh pgo-thin-fdoipra
sbatch benchmarks/hpcc-gcc.sh pgo-thin-fdoipra2 regprof3
sbatch benchmarks/hpcc-leveldb.sh pgo-thin-fdoipra3 regprof3
sbatch benchmarks/hpcc-mongodb.sh pgo-thin