#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=100w_real_sim_overlap
#SBATCH --array=0-71
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb_100w/overlaps/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb_100w/overlaps/logs/overlap_%A_%a.err
#SBATCH --mem=16G

set -e

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

BASE="/cta/users/guneyn23"
REAL_DAMAGE_DIR="${BASE}/damageseq_data"
SIM_DAMAGE_DIR="${BASE}/damageseq_data/simulation"
REAL_OUTPUT_DIR="${BASE}/peak_center_20kb_100w/overlaps/real"
SIM_OUTPUT_DIR="${BASE}/peak_center_20kb_100w/overlaps/simulated"

REGIONS=(
    "ATAC"
    "H3K9me3"
    "H3K27me3"
)

WINDOW_FILES=(
    "${BASE}/peak_center_20kb_100w/ATAC_100windows.bed"
    "${BASE}/peak_center_20kb_100w/H3K9me3_100windows.bed"
    "${BASE}/peak_center_20kb_100w/H3K27me3_100windows.bed"
)

REAL_DAMAGE_FILES=("${REAL_DAMAGE_DIR}"/*.bed)
SIM_DAMAGE_FILES=("${SIM_DAMAGE_DIR}"/*_sim.bed)
DAMAGE_FILES=("${REAL_DAMAGE_FILES[@]}" "${SIM_DAMAGE_FILES[@]}")

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
DAMAGE_INDEX=$((SLURM_ARRAY_TASK_ID % 24))

REGION="${REGIONS[$REGION_INDEX]}"
WINDOW_FILE="${WINDOW_FILES[$REGION_INDEX]}"
DAMAGE_FILE="${DAMAGE_FILES[$DAMAGE_INDEX]}"
DAMAGE_NAME="$(basename "${DAMAGE_FILE}" .bed)"

if (( DAMAGE_INDEX < 12 )); then
    OUTPUT_FILE="${REAL_OUTPUT_DIR}/${DAMAGE_NAME}_${REGION}_100windows_overlap.bed"
else
    OUTPUT_FILE="${SIM_OUTPUT_DIR}/${DAMAGE_NAME}_${REGION}_100windows_overlap.bed"
fi

echo "Array task: ${SLURM_ARRAY_TASK_ID}"
echo "Region: ${REGION}"
echo "Damage: ${DAMAGE_FILE}"
echo "Output: ${OUTPUT_FILE}"

bedtools intersect \
    -a "${WINDOW_FILE}" \
    -b "${DAMAGE_FILE}" \
    -wa \
    -F 0.51 \
    -c \
    > "${OUTPUT_FILE}"

echo "Job completed"
date
