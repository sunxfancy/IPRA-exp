#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=126
#SBATCH --cpus-per-task=1
#SBATCH --mem=200G
#SBATCH --time=0-02:00:00     # 2 hours
#SBATCH --job-name="ipra-bench"
#SBATCH -p short
#SBATCH --constraint=intel

##### //SBATCH --mail-user=xsun042@ucr.edu
##### //SBATCH --mail-type=ALL

module load singularity

echo $SLURM_PROCID-$SLURM_JOBID
echo Benchmark: $1
rm -rf /scratch/$SLURM_JOBID

function run_bench() {
    for i in {0..8}; do
        mkdir -p /scratch/$SLURM_JOBID/$2/$i
    done

    srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/0 benchmarks/$1/$2.$3 &
    if [[ "$2" == *"fdoipra"* ]]; then
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/1 benchmarks/$1/$2.1-10.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/2 benchmarks/$1/$2.1-20.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/3 benchmarks/$1/$2.3-10.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/4 benchmarks/$1/$2.3-20.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/5 benchmarks/$1/$2.5-10.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/6 benchmarks/$1/$2.5-20.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/7 benchmarks/$1/$2.10-10.$3 &
        srun --exclusive --ntasks 1 singularity exec singularity/image.sif make BUILD_PATH=/scratch/$SLURM_JOBID/$2/8 benchmarks/$1/$2.10-20.$3 &
    fi
}

run_bench $1 pgo-full bench
run_bench $1 pgo-full-fdoipra bench
run_bench $1 pgo-full-fdoipra2 bench
run_bench $1 pgo-full-fdoipra3 bench
run_bench $1 pgo-full-bfdoipra bench
run_bench $1 pgo-full-bfdoipra2 bench
run_bench $1 pgo-full-bfdoipra3 bench
run_bench $1 pgo-full-ipra bench
run_bench $1 pgo-full-fdoipra4 bench
run_bench $1 pgo-full-fdoipra5 bench
run_bench $1 pgo-full-fdoipra6 bench
run_bench $1 pgo-full-bfdoipra4 bench
run_bench $1 pgo-full-bfdoipra5 bench
run_bench $1 pgo-full-bfdoipra6 bench
wait
rm -rf /scratch/$SLURM_JOBID