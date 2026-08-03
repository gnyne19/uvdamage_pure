#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=snsMean100kb
#SBATCH --array=0-11%4
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/seaborn_mean_analysis/logs/sns_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/seaborn_mean_analysis/logs/sns_%A_%a.err
set -euo pipefail
BASE="/cta/users/guneyn23"
REGIONS=("ATAC" "H3K9me3" "H3K27me3")
DAMAGES=("64" "CPD")
KINDS=("real" "sim")
K=$((SLURM_ARRAY_TASK_ID % 2))
D=$(((SLURM_ARRAY_TASK_ID / 2) % 2))
R=$((SLURM_ARRAY_TASK_ID / 4))
source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate plot_env
python "${BASE}/peak_center_100kb/seaborn_mean_analysis/seaborn_mean_analysis.py" \
  seaborn --region "${REGIONS[$R]}" --damage "${DAMAGES[$D]}" \
  --kind "${KINDS[$K]}" --n-boot 100
