#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_strand_overlap
#SBATCH --array=0-71
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/overlap_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
STRAND_DIR="${BASE}/damageseq_data/notDS_strand"
OUTPUT_DIR="${BASE}/peak_center_20kb/notDS_strand_3states/overlaps"
REGIONS=("ATAC" "H3K9me3" "H3K27me3")
WINDOW_FILES=(
    "${BASE}/peak_center_20kb/atac_peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_400windows.bed"
    "${BASE}/peak_center_20kb/close_peak_center_20kb/H3K9me3_400_center_windows.bed"
    "${BASE}/peak_center_20kb/close_peak_center_20kb/H3K27me3_400_center_windows.bed"
)
STRANDS=("plus" "minus")
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

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
WITHIN_REGION=$((SLURM_ARRAY_TASK_ID % 24))
STRAND_INDEX=$((WITHIN_REGION / 12))
SAMPLE_INDEX=$((WITHIN_REGION % 12))
REGION="${REGIONS[$REGION_INDEX]}"
WINDOW_FILE="${WINDOW_FILES[$REGION_INDEX]}"
STRAND="${STRANDS[$STRAND_INDEX]}"
SAMPLE="${SAMPLES[$SAMPLE_INDEX]}"
READS="${STRAND_DIR}/${SAMPLE}_notDS_${STRAND}.bed"
OUTPUT="${OUTPUT_DIR}/${SAMPLE}_notDS_${STRAND}_${REGION}_400windows_overlap.bed"
TEMP="${OUTPUT}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"
[[ -s "${WINDOW_FILE}" ]] || { echo "Missing windows: ${WINDOW_FILE}" >&2; exit 1; }
[[ -s "${READS}" ]] || { echo "Missing strand BED: ${READS}" >&2; exit 1; }
trap 'rm -f "${TEMP}"' EXIT

source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate atacseq
bedtools intersect -a "${WINDOW_FILE}" -b "${READS}" -wa -F 0.51 -c > "${TEMP}"

mv "${TEMP}" "${OUTPUT}"
trap - EXIT
echo "region=${REGION} strand=${STRAND} sample=${SAMPLE} rows=$(wc -l < "${OUTPUT}")"

