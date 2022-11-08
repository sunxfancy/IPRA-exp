#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --time=0-02:00:00     # 1 day
#SBATCH --mail-user=xsun042@ucr.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name="ipra-gcc"
#SBATCH -p intel

# Load singularity
module load singularity

echo $SLURM_PROCID-$SLURM_JOBID

rm -rf /scratch/gcc/

singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra2
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra2.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra3
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-fdoipra3.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-bfdoipra
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-bfdoipra.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-bfdoipra2
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-bfdoipra2.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-bfdoipra3
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-bfdoipra3.bench
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full.perfdata

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-ipra
# make BUILD_PATH=/scratch benchmarks/gcc/pgo-full-ipra.bench

# tar -cf result-gcc.tar /scratch/benchmarks/gcc
# rm -rf /scratch/benchmarks/gcc