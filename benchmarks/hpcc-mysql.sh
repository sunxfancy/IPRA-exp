#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --time=0-02:00:00     # 2 hours
#SBATCH --mail-user=xsun042@ucr.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name="ipra-mysql"
#SBATCH -p short
#SBATCH --constraint=intel

# Load singularity
module load singularity

echo $SLURM_PROCID-$SLURM_JOBID

rm -rf /scratch/mysql/

singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra2
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra2.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra3
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-fdoipra3.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-bfdoipra
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-bfdoipra.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-bfdoipra2
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-bfdoipra2.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata
# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-bfdoipra3
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-bfdoipra3.bench
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full.perfdata

# singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-ipra
# make BUILD_PATH=/scratch benchmarks/mysql/pgo-full-ipra.bench

# tar -cf result-mysql.tar /scratch/benchmarks/mysql
# rm -rf /scratch/benchmarks/mysql