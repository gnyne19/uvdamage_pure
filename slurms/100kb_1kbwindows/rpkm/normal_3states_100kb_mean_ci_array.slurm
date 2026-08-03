#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=meanCI100kb
#SBATCH --array=0-71
#SBATCH --mem=4G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/mean_ci_analysis/logs/mean_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/mean_ci_analysis/logs/mean_%A_%a.err

set -euo pipefail
BASE="/cta/users/guneyn23"
RPKM_DIR="${BASE}/peak_center_100kb/normal_3states/rpkm"
PART_DIR="${BASE}/peak_center_100kb/mean_ci_analysis/parts"
REGIONS=("ATAC" "H3K9me3" "H3K27me3")
DAMAGES=("64" "CPD")
KINDS=("real" "sim")
TIMES=("1m" "15m" "30m" "1h" "4h" "8h")
T=$((SLURM_ARRAY_TASK_ID % 6))
K=$(((SLURM_ARRAY_TASK_ID / 6) % 2))
D=$(((SLURM_ARRAY_TASK_ID / 12) % 2))
R=$((SLURM_ARRAY_TASK_ID / 24))
TIME="${TIMES[$T]}"; KIND="${KINDS[$K]}"
DAMAGE="${DAMAGES[$D]}"; REGION="${REGIONS[$R]}"
INPUT="${RPKM_DIR}/${TIME}_${DAMAGE}_${KIND}_${REGION}_100windows_rpkm.bed"
OUTPUT="${PART_DIR}/${REGION}_${DAMAGE}_${TIME}_${KIND}_mean_ci.tsv"
mkdir -p "${PART_DIR}"
source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate plot_env
python "${BASE}/peak_center_100kb/mean_ci_analysis/mean_ci_analysis.py" summarize \
  --input "${INPUT}" --output "${OUTPUT}" --region "${REGION}" \
  --damage "${DAMAGE}" --time "${TIME}" --kind "${KIND}"
