#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_ATAC_overlap
#SBATCH --array=0-11
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_noUV_ATAC/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_noUV_ATAC/logs/overlap_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
WINDOW_FILE="${BASE}/peak_center_20kb/atac_peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_400windows.bed"
NOTDS_DIR="${BASE}/damageseq_data/notDS"
OUTPUT_DIR="${BASE}/peak_center_20kb/notDS_noUV_ATAC/overlaps"

NOTDS_FILES=(
    "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_notDS.bed"
    "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_notDS.bed"
    "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_notDS.bed"
    "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_notDS.bed"
    "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_notDS.bed"
    "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_notDS.bed"
    "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_notDS.bed"
    "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_notDS.bed"
    "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_notDS.bed"
    "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_notDS.bed"
    "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_notDS.bed"
    "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_notDS.bed"
)

NOTDS_NAME="${NOTDS_FILES[$SLURM_ARRAY_TASK_ID]}"
NOTDS_FILE="${NOTDS_DIR}/${NOTDS_NAME}"
SAMPLE="${NOTDS_NAME%_notDS.bed}"
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE}_notDS_noUV_ATAC_400windows_overlap.bed"
TEMP_FILE="${OUTPUT_FILE}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"

[[ -s "${WINDOW_FILE}" ]] || { echo "Missing window file: ${WINDOW_FILE}" >&2; exit 1; }
[[ -s "${NOTDS_FILE}" ]] || { echo "Missing notDS file: ${NOTDS_FILE}" >&2; exit 1; }

trap 'rm -f "${TEMP_FILE}"' EXIT

source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate atacseq

echo "Started: $(date)"
echo "notDS: ${NOTDS_FILE}"
echo "Output: ${OUTPUT_FILE}"

bedtools intersect \
    -a "${WINDOW_FILE}" \
    -b "${NOTDS_FILE}" \
    -wa \
    -F 0.51 \
    -c \
    > "${TEMP_FILE}"

mv "${TEMP_FILE}" "${OUTPUT_FILE}"
trap - EXIT

echo "Output rows: $(wc -l < "${OUTPUT_FILE}")"
echo "Completed: $(date)"
