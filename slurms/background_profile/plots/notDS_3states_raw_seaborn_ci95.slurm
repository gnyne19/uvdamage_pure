#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_raw_ci95
#SBATCH --array=0-5
#SBATCH --mem=64G

#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_3states/logs/raw_ci95_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_3states/logs/raw_ci95_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
REGIONS=("ATAC" "ATAC" "H3K9me3" "H3K9me3" "H3K27me3" "H3K27me3")
DAMAGES=("64" "CPD" "64" "CPD" "64" "CPD")

REGION="${REGIONS[$SLURM_ARRAY_TASK_ID]}"
DAMAGE="${DAMAGES[$SLURM_ARRAY_TASK_ID]}"

source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate plot_env

python "${BASE}/peak_center_20kb/notDS_3states/raw_seaborn_ci95_plot.py" \
    "${REGION}" \
    "${DAMAGE}" \
    --n-boot 100
