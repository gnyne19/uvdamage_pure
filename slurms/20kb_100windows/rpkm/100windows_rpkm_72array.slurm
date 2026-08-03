#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=100w_rpkm
#SBATCH --array=0-71
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb_100w/rpkm/logs/rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb_100w/rpkm/logs/rpkm_%A_%a.err
#SBATCH --mem=16G

set -e

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

BASE="/cta/users/guneyn23"
RPKM_SCRIPT="${BASE}/peak_center_20kb_100w/rpkm/calculate_rpkm.py"
REAL_DAMAGE_DIR="${BASE}/damageseq_data"
SIM_DAMAGE_DIR="${BASE}/damageseq_data/simulation"
REAL_OVERLAP_DIR="${BASE}/peak_center_20kb_100w/overlaps/real"
SIM_OVERLAP_DIR="${BASE}/peak_center_20kb_100w/overlaps/simulated"
REAL_OUTPUT_DIR="${BASE}/peak_center_20kb_100w/rpkm/real"
SIM_OUTPUT_DIR="${BASE}/peak_center_20kb_100w/rpkm/simulated"

REGIONS=(
    "ATAC"
    "H3K9me3"
    "H3K27me3"
)

REAL_DAMAGE_FILES=("${REAL_DAMAGE_DIR}"/*.bed)
SIM_DAMAGE_FILES=("${SIM_DAMAGE_DIR}"/*_sim.bed)
DAMAGE_FILES=("${REAL_DAMAGE_FILES[@]}" "${SIM_DAMAGE_FILES[@]}")

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
DAMAGE_INDEX=$((SLURM_ARRAY_TASK_ID % 24))

REGION="${REGIONS[$REGION_INDEX]}"
DAMAGE_FILE="${DAMAGE_FILES[$DAMAGE_INDEX]}"
DAMAGE_NAME="$(basename "${DAMAGE_FILE}" .bed)"
TIME_DAMAGE="${DAMAGE_NAME#R3Hela_}"
TIME_DAMAGE="${TIME_DAMAGE%%_*}"

if [[ "${TIME_DAMAGE}" =~ ^(1m|15m|30m|1h|4h|8h)(CPD|64)$ ]]; then
    TIME_POINT="${BASH_REMATCH[1]}"
    DAMAGE_TYPE="${BASH_REMATCH[2]}"
fi

if (( DAMAGE_INDEX < 12 )); then
    OVERLAP_FILE="${REAL_OVERLAP_DIR}/${TIME_POINT}_${DAMAGE_TYPE}_real_${REGION}_100windows_overlap.bed"
    RPKM_FILE="${REAL_OUTPUT_DIR}/${TIME_POINT}_${DAMAGE_TYPE}_real_${REGION}_100windows_rpkm.bed"
else
    OVERLAP_FILE="${SIM_OVERLAP_DIR}/${TIME_POINT}_${DAMAGE_TYPE}_sim_${REGION}_100windows_overlap.bed"
    RPKM_FILE="${SIM_OUTPUT_DIR}/${TIME_POINT}_${DAMAGE_TYPE}_sim_${REGION}_100windows_rpkm.bed"
fi

echo "Array task: ${SLURM_ARRAY_TASK_ID}"
echo "Region: ${REGION}"
echo "Overlap file: ${OVERLAP_FILE}"
echo "Damage file: ${DAMAGE_FILE}"
echo "RPKM file: ${RPKM_FILE}"

python "${RPKM_SCRIPT}" \
    "${OVERLAP_FILE}" \
    "${DAMAGE_FILE}" \
    "${RPKM_FILE}"

echo "Job completed"
date
