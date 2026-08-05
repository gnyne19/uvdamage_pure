#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=nonwindowed_rpkm
#SBATCH --array=0-19
#SBATCH --output=/cta/users/guneyn23/non_windowed/nonwindowed_rpkm/logs/rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/non_windowed/nonwindowed_rpkm/logs/rpkm_%A_%a.err
#SBATCH --mem=4G

set -euo pipefail
BASE="/cta/users/guneyn23"
PEAK_SETS=("noUV_IDR_ATAC" "4h_UV_specific" "4h_noUV_specific" "8h_UV_specific" "8h_noUV_specific")
DAMAGES=("CPD" "64")
KINDS=("real" "sim")
PEAK_SET="${PEAK_SETS[$((SLURM_ARRAY_TASK_ID / 4))]}"
WITHIN=$((SLURM_ARRAY_TASK_ID % 4))
DAMAGE="${DAMAGES[$((WITHIN / 2))]}"
KIND="${KINDS[$((WITHIN % 2))]}"
python "${BASE}/uvdamage_pure/scripts/non_windowed/calculate_relative_rpkm.py" --peak-set "${PEAK_SET}" --damage "${DAMAGE}" --kind "${KIND}"
