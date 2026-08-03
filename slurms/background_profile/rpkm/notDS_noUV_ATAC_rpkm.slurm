#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_ATAC_rpkm
#SBATCH --array=0-11
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_noUV_ATAC/logs/rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_noUV_ATAC/logs/rpkm_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
NOTDS_DIR="${BASE}/damageseq_data/notDS"
OVERLAP_DIR="${BASE}/peak_center_20kb/notDS_noUV_ATAC/overlaps"
OUTPUT_DIR="${BASE}/peak_center_20kb/notDS_noUV_ATAC/rpkm"
WINDOW_BP=50

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

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"
NOTDS_FILE="${NOTDS_DIR}/${SAMPLE}_notDS.bed"
OVERLAP_FILE="${OVERLAP_DIR}/${SAMPLE}_notDS_noUV_ATAC_400windows_overlap.bed"
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE}_notDS_noUV_ATAC_400windows_rpkm.bed"
TEMP_FILE="${OUTPUT_FILE}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"

[[ -s "${NOTDS_FILE}" ]] || { echo "Missing notDS file: ${NOTDS_FILE}" >&2; exit 1; }
[[ -s "${OVERLAP_FILE}" ]] || { echo "Missing overlap file: ${OVERLAP_FILE}" >&2; exit 1; }

trap 'rm -f "${TEMP_FILE}"' EXIT

TOTAL_READS=$(wc -l < "${NOTDS_FILE}")
if (( TOTAL_READS == 0 )); then
    echo "notDS file has zero reads: ${NOTDS_FILE}" >&2
    exit 1
fi

echo "Started: $(date)"
echo "Sample: ${SAMPLE}"
echo "Total notDS reads: ${TOTAL_READS}"
echo "Window length: ${WINDOW_BP} bp"

# Input columns: chrom, start, end, peak_window, overlap_count.
# Append RPKM = notDS count * 10^9 / (total_notDS_reads * 50 bp).
LC_ALL=C awk -F $'\t' -v total="${TOTAL_READS}" -v window_bp="${WINDOW_BP}" '
    BEGIN { OFS = FS }
    {
        rpkm = ($NF * 1000000000) / (total * window_bp)
        print $0, sprintf("%.6f", rpkm)
    }
' "${OVERLAP_FILE}" > "${TEMP_FILE}"

mv "${TEMP_FILE}" "${OUTPUT_FILE}"
trap - EXIT

echo "Output: ${OUTPUT_FILE}"
echo "Output rows: $(wc -l < "${OUTPUT_FILE}")"
echo "Completed: $(date)"
