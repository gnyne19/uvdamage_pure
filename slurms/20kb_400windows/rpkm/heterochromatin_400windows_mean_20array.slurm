#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=het_400w_mean
#SBATCH --array=0-19
#SBATCH --output=/cta/users/guneyn23/relative_repair/direct_rpkm_all_timepoints/logs/het_mean_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/relative_repair/direct_rpkm_all_timepoints/logs/het_mean_%A_%a.err
#SBATCH --mem=4G

set -euo pipefail

BASE="/cta/users/guneyn23"
INPUT_BASE="${BASE}/peak_center_20kb/close_rpkm"
OUTPUT_DIR="${BASE}/relative_repair/direct_rpkm_all_timepoints"
PYTHON_SCRIPT="${OUTPUT_DIR}/calculate_heterochromatin_window_means.py"

REGIONS=("H3K9me3" "H3K27me3")

DAMAGES=(
    "CPD" "CPD" "CPD" "CPD" "CPD"
    "64"  "64"  "64"  "64"  "64"
)

TIMES=(
    "15m" "30m" "1h" "4h" "8h"
    "15m" "30m" "1h" "4h" "8h"
)

STEMS=(
    "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS"
    "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS"
    "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS"
    "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS"
    "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS"
    "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS"
    "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS"
    "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS"
    "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS"
    "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS"
)

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 10))
SAMPLE_INDEX=$((SLURM_ARRAY_TASK_ID % 10))

REGION="${REGIONS[$REGION_INDEX]}"
DAMAGE="${DAMAGES[$SAMPLE_INDEX]}"
TIME="${TIMES[$SAMPLE_INDEX]}"
STEM="${STEMS[$SAMPLE_INDEX]}"

REAL_RPKM="${INPUT_BASE}/${REGION}/${STEM}_${REGION}_400windows_rpkm.bed"
SIM_RPKM="${INPUT_BASE}/${REGION}/${STEM}_sim_${REGION}_400windows_rpkm.bed"
OUTPUT_TSV="${OUTPUT_DIR}/${REGION}_${DAMAGE}_${TIME}_mean_rpkm_ratio.tsv"

echo "Region: ${REGION}"
echo "Damage: ${DAMAGE}"
echo "Time: ${TIME}"
echo "Real RPKM: ${REAL_RPKM}"
echo "Sim RPKM: ${SIM_RPKM}"
echo "Output TSV: ${OUTPUT_TSV}"

python "${PYTHON_SCRIPT}" \
    "${REAL_RPKM}" \
    "${SIM_RPKM}" \
    "${OUTPUT_TSV}"
