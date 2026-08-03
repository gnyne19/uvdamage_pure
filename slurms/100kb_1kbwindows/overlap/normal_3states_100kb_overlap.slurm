#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=normal_3states_100kb_overlap
#SBATCH --array=0-71
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/normal_3states/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/normal_3states/logs/overlap_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
REAL_DIR="${BASE}/damageseq_data"
SIM_DIR="${REAL_DIR}/simulation"
OUTPUT_DIR="${BASE}/peak_center_100kb/normal_3states/overlaps"
OLD_OVERLAP_DIR="${BASE}/peak_center_100kb/overlaps"

REGIONS=("ATAC" "H3K9me3" "H3K27me3")
WINDOW_TEMPLATES=(
    "${OLD_OVERLAP_DIR}/ATAC_64_real_overlap.bed"
    "${OLD_OVERLAP_DIR}/H3K9me3_64_real_overlap.bed"
    "${OLD_OVERLAP_DIR}/H3K27me3_64_real_overlap.bed"
)

DAMAGE_FILES=(
    "${REAL_DIR}/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_sim.bed"
    "${REAL_DIR}/R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS.bed"
    "${SIM_DIR}/R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_sim.bed"
)

LABELS=(
    "1m_64_real" "1m_64_sim" "15m_64_real" "15m_64_sim"
    "30m_64_real" "30m_64_sim" "1h_64_real" "1h_64_sim"
    "4h_64_real" "4h_64_sim" "8h_64_real" "8h_64_sim"
    "1m_CPD_real" "1m_CPD_sim" "15m_CPD_real" "15m_CPD_sim"
    "30m_CPD_real" "30m_CPD_sim" "1h_CPD_real" "1h_CPD_sim"
    "4h_CPD_real" "4h_CPD_sim" "8h_CPD_real" "8h_CPD_sim"
)

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
SAMPLE_INDEX=$((SLURM_ARRAY_TASK_ID % 24))

REGION="${REGIONS[$REGION_INDEX]}"
WINDOW_TEMPLATE="${WINDOW_TEMPLATES[$REGION_INDEX]}"
DAMAGE_FILE="${DAMAGE_FILES[$SAMPLE_INDEX]}"
LABEL="${LABELS[$SAMPLE_INDEX]}"
OUTPUT_FILE="${OUTPUT_DIR}/${LABEL}_${REGION}_100windows_overlap.bed"
TEMP_OUTPUT="${OUTPUT_FILE}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"
WINDOW_FILE="${TMPDIR:-/tmp}/${REGION}_100windows_1kb_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.bed"

mkdir -p "${OUTPUT_DIR}"
[[ -s "${WINDOW_TEMPLATE}" ]] || { echo "Missing template: ${WINDOW_TEMPLATE}" >&2; exit 1; }
[[ -s "${DAMAGE_FILE}" ]] || { echo "Missing damage file: ${DAMAGE_FILE}" >&2; exit 1; }
trap 'rm -f "${WINDOW_FILE}" "${TEMP_OUTPUT}"' EXIT

# Recover the exact 100 x 1-kb windows from the existing 1m intersect -c file.
LC_ALL=C awk -F $'\t' 'BEGIN {OFS=FS} {print $1,$2,$3,$4}' \
    "${WINDOW_TEMPLATE}" > "${WINDOW_FILE}"

source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate atacseq

bedtools intersect \
    -a "${WINDOW_FILE}" \
    -b "${DAMAGE_FILE}" \
    -wa \
    -F 0.51 \
    -c \
    > "${TEMP_OUTPUT}"

mv "${TEMP_OUTPUT}" "${OUTPUT_FILE}"
rm -f "${WINDOW_FILE}"
trap - EXIT

echo "Region: ${REGION}"
echo "Sample: ${LABEL}"
echo "Output: ${OUTPUT_FILE}"
echo "Rows: $(wc -l < "${OUTPUT_FILE}")"
