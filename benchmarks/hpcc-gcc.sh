#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=0-02:00:00     # 2 hours
#SBATCH --job-name="ipra-gcc"
#SBATCH -p short
#SBATCH --constraint=intel

##### //SBATCH --mail-user=xsun042@ucr.edu
##### //SBATCH --mail-type=ALL

module load singularity

echo $SLURM_PROCID-$SLURM_JOBID
echo Build gcc: $1
echo Action: $2

rm -rf /scratch/gcc/
singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1

if [[ "$2" != "" ]]; then
    singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.$2
    if [[ "$1" == *"fdoipra"* ]]; then
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.1-10.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.1-20.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.3-10.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.3-20.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.5-10.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.5-20.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.10-10.$2
        singularity exec singularity/image.sif make BUILD_PATH=/scratch benchmarks/gcc/$1.10-20.$2
    fi
fi