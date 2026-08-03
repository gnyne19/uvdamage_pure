#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=median100kb
#SBATCH --array=0-71
#SBATCH --mem=4G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/median_analysis/logs/median_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/median_analysis/logs/median_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
RPKM_DIR="${BASE}/peak_center_100kb/normal_3states/rpkm"
PART_DIR="${BASE}/peak_center_100kb/median_analysis/parts"
REGIONS=("ATAC" "H3K9me3" "H3K27me3")
DAMAGES=("64" "CPD")
KINDS=("real" "sim")
TIMES=("1m" "15m" "30m" "1h" "4h" "8h")

TIME_INDEX=$((SLURM_ARRAY_TASK_ID % 6))
KIND_INDEX=$(((SLURM_ARRAY_TASK_ID / 6) % 2))
DAMAGE_INDEX=$(((SLURM_ARRAY_TASK_ID / 12) % 2))
REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 24))

TIME="${TIMES[$TIME_INDEX]}"
KIND="${KINDS[$KIND_INDEX]}"
DAMAGE="${DAMAGES[$DAMAGE_INDEX]}"
REGION="${REGIONS[$REGION_INDEX]}"
INPUT="${RPKM_DIR}/${TIME}_${DAMAGE}_${KIND}_${REGION}_100windows_rpkm.bed"
OUTPUT="${PART_DIR}/${REGION}_${DAMAGE}_${TIME}_${KIND}_median.tsv"

mkdir -p "${PART_DIR}"
[[ -s "${INPUT}" ]] || { echo "Missing input: ${INPUT}" >&2; exit 1; }
source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate plot_env
python "${BASE}/peak_center_100kb/median_analysis/median_analysis.py" summarize \
    --input "${INPUT}" --output "${OUTPUT}" \
    --region "${REGION}" --damage "${DAMAGE}" \
    --time "${TIME}" --kind "${KIND}"

