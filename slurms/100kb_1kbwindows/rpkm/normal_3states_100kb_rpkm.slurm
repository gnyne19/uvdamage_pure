#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=normal_3states_100kb_rpkm
#SBATCH --array=0-71
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/normal_3states/logs/rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/normal_3states/logs/rpkm_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
REAL_DIR="${BASE}/damageseq_data"
SIM_DIR="${REAL_DIR}/simulation"
OVERLAP_DIR="${BASE}/peak_center_100kb/normal_3states/overlaps"
OUTPUT_DIR="${BASE}/peak_center_100kb/normal_3states/rpkm"
WINDOW_BP=1000

REGIONS=("ATAC" "H3K9me3" "H3K27me3")
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
DAMAGE_FILE="${DAMAGE_FILES[$SAMPLE_INDEX]}"
LABEL="${LABELS[$SAMPLE_INDEX]}"
OVERLAP_FILE="${OVERLAP_DIR}/${LABEL}_${REGION}_100windows_overlap.bed"
OUTPUT_FILE="${OUTPUT_DIR}/${LABEL}_${REGION}_100windows_rpkm.bed"
TEMP_FILE="${OUTPUT_FILE}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"
[[ -s "${DAMAGE_FILE}" ]] || { echo "Missing damage file: ${DAMAGE_FILE}" >&2; exit 1; }
[[ -s "${OVERLAP_FILE}" ]] || { echo "Missing overlap file: ${OVERLAP_FILE}" >&2; exit 1; }
trap 'rm -f "${TEMP_FILE}"' EXIT

TOTAL_READS=$(wc -l < "${DAMAGE_FILE}")
(( TOTAL_READS > 0 )) || { echo "Zero reads: ${DAMAGE_FILE}" >&2; exit 1; }

LC_ALL=C awk -F $'\t' -v total="${TOTAL_READS}" -v window_bp="${WINDOW_BP}" '
    BEGIN {OFS=FS}
    {
        rpkm=($NF*1000000000)/(total*window_bp)
        print $0,sprintf("%.6f",rpkm)
    }
' "${OVERLAP_FILE}" > "${TEMP_FILE}"

mv "${TEMP_FILE}" "${OUTPUT_FILE}"
trap - EXIT

echo "Region: ${REGION}"
echo "Sample: ${LABEL}"
echo "Total reads: ${TOTAL_READS}"
echo "Output: ${OUTPUT_FILE}"
