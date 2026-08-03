#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_hetero_rpkm
#SBATCH --array=0-23
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_3states/logs/hetero_rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_3states/logs/hetero_rpkm_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
NOTDS_DIR="${BASE}/damageseq_data/notDS"
OVERLAP_DIR="${BASE}/peak_center_20kb/notDS_3states/overlaps"
OUTPUT_DIR="${BASE}/peak_center_20kb/notDS_3states/rpkm"
WINDOW_BP=50

REGIONS=("H3K9me3" "H3K27me3")
SAMPLES=(
    "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly"
    "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly"
    "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly"
    "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly"
    "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly"
    "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly"
    "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly"
    "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly"
    "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly"
    "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly"
    "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly"
    "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly"
)

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 12))
SAMPLE_INDEX=$((SLURM_ARRAY_TASK_ID % 12))
REGION="${REGIONS[$REGION_INDEX]}"
SAMPLE="${SAMPLES[$SAMPLE_INDEX]}"
NOTDS_FILE="${NOTDS_DIR}/${SAMPLE}_notDS.bed"
OVERLAP_FILE="${OVERLAP_DIR}/${SAMPLE}_notDS_${REGION}_400windows_overlap.bed"
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE}_notDS_${REGION}_400windows_rpkm.bed"
TEMP_FILE="${OUTPUT_FILE}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"
[[ -s "${NOTDS_FILE}" ]] || { echo "Missing notDS: ${NOTDS_FILE}" >&2; exit 1; }
[[ -s "${OVERLAP_FILE}" ]] || { echo "Missing overlap: ${OVERLAP_FILE}" >&2; exit 1; }
trap 'rm -f "${TEMP_FILE}"' EXIT

TOTAL_NOTDS_READS=$(wc -l < "${NOTDS_FILE}")
(( TOTAL_NOTDS_READS > 0 )) || { echo "Zero notDS reads" >&2; exit 1; }

LC_ALL=C awk -F $'\t' -v total="${TOTAL_NOTDS_READS}" -v window_bp="${WINDOW_BP}" '
    BEGIN {OFS=FS}
    {
        rpkm=($NF*1000000000)/(total*window_bp)
        print $0,sprintf("%.6f",rpkm)
    }
' "${OVERLAP_FILE}" > "${TEMP_FILE}"

mv "${TEMP_FILE}" "${OUTPUT_FILE}"
trap - EXIT
echo "Region: ${REGION}"
echo "Sample: ${SAMPLE}"
echo "Total notDS reads: ${TOTAL_NOTDS_READS}"
echo "Output: ${OUTPUT_FILE}"
