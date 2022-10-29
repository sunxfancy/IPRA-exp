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

singularity exec singularity/image.sif make benchmarks/clang/pgo-full
make benchmarks/clang/pgo-full.bench
make benchmarks/clang/pgo-full.perfdata

singularity exec singularity/image.sif make benchmarks/clang/pgo-full-fdoipra
make benchmarks/clang/pgo-full-fdoipra.bench
make benchmarks/clang/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/clang/pgo-full-fdoipra2
make benchmarks/clang/pgo-full-fdoipra2.bench
make benchmarks/clang/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/clang/pgo-full-fdoipra3
make benchmarks/clang/pgo-full-fdoipra3.bench
make benchmarks/clang/pgo-full.perfdata

singularity exec singularity/image.sif make benchmarks/clang/pgo-full-bfdoipra
make benchmarks/clang/pgo-full-bfdoipra.bench
make benchmarks/clang/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/clang/pgo-full-bfdoipra2
make benchmarks/clang/pgo-full-bfdoipra2.bench
make benchmarks/clang/pgo-full.perfdata
singularity exec singularity/image.sif make benchmarks/clang/pgo-full-bfdoipra3
make benchmarks/clang/pgo-full-bfdoipra3.bench
make benchmarks/clang/pgo-full.perfdata

singularity exec singularity/image.sif make benchmarks/clang/pgo-full-ipra
make benchmarks/clang/pgo-full-ipra.bench

tar -cf result.tar /scratch/xsun042
rm -rf /scratch/xsun042