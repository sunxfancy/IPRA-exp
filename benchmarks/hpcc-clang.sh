#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --time=0-02:00:00     # 2 hours
#SBATCH --job-name="ipra-clang"
#SBATCH -p short
#SBATCH --constraint=intel

##### //SBATCH --mail-user=xsun042@ucr.edu
##### //SBATCH --mail-type=ALL

module load singularity

echo $SLURM_PROCID-$SLURM_JOBID
echo Build clang: $1
rm -rf /scratch/clang/

singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/clang/$1
