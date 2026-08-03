#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=sim_relative_repair
#SBATCH --array=0-9%2
#SBATCH --output=/cta/users/guneyn23/sim_relative_repair/logs/sim_repair_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/sim_relative_repair/logs/sim_repair_%A_%a.err
#SBATCH --mem=4G
#SBATCH --time=12:00:00

set -e

BASE_DIR="/cta/users/guneyn23"
LATER_DIR="${BASE_DIR}/peak_center_20kb/rpkm/noUV_atac_damage_all"
OUTPUT_DIR="${BASE_DIR}/sim_relative_repair"
SCRIPT="${OUTPUT_DIR}/calculate_sim_relative_repair.py"

LATER_FILES=(
    "${LATER_DIR}/R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
    "${LATER_DIR}/R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed"
)

OUTPUT_NAMES=(
    "CPD_15m_sim_relative_repair.tsv"
    "CPD_30m_sim_relative_repair.tsv"
    "CPD_1h_sim_relative_repair.tsv"
    "CPD_4h_sim_relative_repair.tsv"
    "CPD_8h_sim_relative_repair.tsv"
    "64_15m_sim_relative_repair.tsv"
    "64_30m_sim_relative_repair.tsv"
    "64_1h_sim_relative_repair.tsv"
    "64_4h_sim_relative_repair.tsv"
    "64_8h_sim_relative_repair.tsv"
)

if (( SLURM_ARRAY_TASK_ID < 5 )); then
    BASELINE_FILE="${BASE_DIR}/rpkm/CPD_rpkm/atac_rpkm/sim_damage_rpkm.bed"
else
    BASELINE_FILE="${BASE_DIR}/rpkm/64_rpkm/ATAC_simulated_64_rpkm.bed"
fi

LATER_FILE="${LATER_FILES[$SLURM_ARRAY_TASK_ID]}"
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_NAMES[$SLURM_ARRAY_TASK_ID]}"

echo "Started: $(date)"
echo "Baseline sim 1m: ${BASELINE_FILE}"
echo "Later sim: ${LATER_FILE}"
echo "Output: ${OUTPUT_FILE}"

python "${SCRIPT}" "${BASELINE_FILE}" "${LATER_FILE}" "${OUTPUT_FILE}"

echo "Completed: $(date)"
