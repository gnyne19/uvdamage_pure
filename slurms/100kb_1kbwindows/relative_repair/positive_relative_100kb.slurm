#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=relative_100kb
#SBATCH --array=0-29%5
#SBATCH --mem=12G
#SBATCH --output=/cta/users/guneyn23/positive_relative/100kb/logs/relative_100kb_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/positive_relative/100kb/logs/relative_100kb_%A_%a.err

set -e

echo "100 kb positive relative repair analysis started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/positive_relative/positive_relative_mean_profiles.py \
  --resolution 100 \
  --task-id "${SLURM_ARRAY_TASK_ID}"

echo "100 kb positive relative repair analysis completed"
date
