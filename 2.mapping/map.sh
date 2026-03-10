#!/bin/bash
#SBATCH --job-name NorMap
#SBATCH --nodes=1
#SBATCH --cpus-per-task=25
#SBATCH --time=04:00:00
#SBATCH --mem=300G
#SBATCH --array=1-6048%15
#SBATCH --export=ALL
#SBATCH --output=NorthMap_%A_%a.out

module load bowtie2
module load samtools
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID
cd /projects/seachange/people/gwm297/SeaChange_WP2/2.mapping/
cmd=$(awk -v line=$SLURM_ARRAY_TASK_ID 'NR == line {print $0}' commands.txt)

# Execute the command or script
eval "$cmd"

