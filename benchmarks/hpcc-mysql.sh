#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --time=1-00:00:00     # 1 day
#SBATCH --mail-user=xsun042@ucr.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name="ipra-clang"
#SBATCH -p intel

# Load singularity
module load singularity

echo $SLURM_PROCID-$SLURM_JOBID

singularity exec singularity/image.sif make benchmarks/mysql/pgo-full
make benchmarks/mysql/pgo-full.bench
make benchmarks/mysql/pgo-full.perfdata

singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-fdoipra
make benchmarks/mysql/pgo-full-fdoipra.bench
make benchmarks/mysql/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-fdoipra2
make benchmarks/mysql/pgo-full-fdoipra2.bench
make benchmarks/mysql/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-fdoipra3
make benchmarks/mysql/pgo-full-fdoipra3.bench
make benchmarks/mysql/pgo-full.perfdata

singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-bfdoipra
make benchmarks/mysql/pgo-full-bfdoipra.bench
make benchmarks/mysql/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-bfdoipra2
make benchmarks/mysql/pgo-full-bfdoipra2.bench
make benchmarks/mysql/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-bfdoipra3
make benchmarks/mysql/pgo-full-bfdoipra3.bench
make benchmarks/mysql/pgo-full.perfdata

singularity exec singularity/image.sif make benchmarks/mysql/pgo-full-ipra
make benchmarks/mysql/pgo-full-ipra.bench

tar -cf result-mysql.tar /scratch/benchmarks/mysql
rm -rf /scratch/benchmarks/mysql