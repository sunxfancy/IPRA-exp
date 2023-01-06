SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sbatch benchmarks/hpcc-clang.sh pgo-full.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra2.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra3.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra2.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra3.bench
sbatch benchmarks/hpcc-clang.sh pgo-full-ipra.bench

sbatch benchmarks/hpcc-mysql.sh pgo-full.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra2.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra3.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra2.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra3.bench
sbatch benchmarks/hpcc-mysql.sh pgo-full-ipra.bench

sbatch benchmarks/hpcc-gcc.sh pgo-full.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra2.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra3.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra2.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra3.bench
sbatch benchmarks/hpcc-gcc.sh pgo-full-ipra.bench


