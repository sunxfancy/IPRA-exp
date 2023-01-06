SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH/..

sbatch benchmarks/hpcc-clang.sh pgo-full.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra2.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-fdoipra3.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra2.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-bfdoipra3.regprof3
sbatch benchmarks/hpcc-clang.sh pgo-full-ipra.regprof3

sbatch benchmarks/hpcc-mysql.sh pgo-full.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra2.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-fdoipra3.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra2.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-bfdoipra3.regprof3
sbatch benchmarks/hpcc-mysql.sh pgo-full-ipra.regprof3

sbatch benchmarks/hpcc-gcc.sh pgo-full.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra2.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-fdoipra3.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra2.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-bfdoipra3.regprof3
sbatch benchmarks/hpcc-gcc.sh pgo-full-ipra.regprof3


