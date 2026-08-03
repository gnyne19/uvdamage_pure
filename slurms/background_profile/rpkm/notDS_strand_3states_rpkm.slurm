#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_strand_rpkm
#SBATCH --array=0-71
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/rpkm_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
STRAND_DIR="${BASE}/damageseq_data/notDS_strand"
OVERLAP_DIR="${BASE}/peak_center_20kb/notDS_strand_3states/overlaps"
OUTPUT_DIR="${BASE}/peak_center_20kb/notDS_strand_3states/rpkm"
WINDOW_BP=50
REGIONS=("ATAC" "H3K9me3" "H3K27me3")
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
STRAND="${STRANDS[$STRAND_INDEX]}"
SAMPLE="${SAMPLES[$SAMPLE_INDEX]}"
READS="${STRAND_DIR}/${SAMPLE}_notDS_${STRAND}.bed"
OVERLAP="${OVERLAP_DIR}/${SAMPLE}_notDS_${STRAND}_${REGION}_400windows_overlap.bed"
OUTPUT="${OUTPUT_DIR}/${SAMPLE}_notDS_${STRAND}_${REGION}_400windows_rpkm.bed"
TEMP="${OUTPUT}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"
[[ -s "${READS}" ]] || { echo "Missing strand BED: ${READS}" >&2; exit 1; }
[[ -s "${OVERLAP}" ]] || { echo "Missing overlap: ${OVERLAP}" >&2; exit 1; }
trap 'rm -f "${TEMP}"' EXIT

TOTAL_STRAND_READS=$(wc -l < "${READS}")
(( TOTAL_STRAND_READS > 0 )) || { echo "Zero ${STRAND} reads: ${READS}" >&2; exit 1; }

LC_ALL=C awk -F $'\t' -v total="${TOTAL_STRAND_READS}" -v bp="${WINDOW_BP}" '
    BEGIN { OFS=FS }
    { print $0, sprintf("%.6f", ($NF * 1000000000)/(total * bp)) }
' "${OVERLAP}" > "${TEMP}"

mv "${TEMP}" "${OUTPUT}"
trap - EXIT
echo "region=${REGION} strand=${STRAND} total_strand_reads=${TOTAL_STRAND_READS}"
echo "output=${OUTPUT}"

