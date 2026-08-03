#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=noUV_closed_sim_damage
#SBATCH --array=0-19
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/noUV_closed_alltime_damage_overlaps/simulated/logs/noUV_closed_sim_damage_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/noUV_closed_alltime_damage_overlaps/simulated/logs/noUV_closed_sim_damage_%A_%a.err
#SBATCH --mem=32G

set -euo pipefail

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

WINDOW_FILES=(
    "/cta/users/guneyn23/peak_center_20kb/close_peak_center_20kb/H3K9me3_400_center_windows.bed"
    "/cta/users/guneyn23/peak_center_20kb/close_peak_center_20kb/H3K27me3_400_center_windows.bed"
)

REGION_NAMES=(
    "H3K9me3"
    "H3K27me3"
)

SIM_DAMAGE_FILES=(
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_sim.bed"
)

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 10))
DAMAGE_INDEX=$((SLURM_ARRAY_TASK_ID % 10))

WINDOW_FILE="${WINDOW_FILES[$REGION_INDEX]}"
REGION_NAME="${REGION_NAMES[$REGION_INDEX]}"
SIM_DAMAGE_FILE="${SIM_DAMAGE_FILES[$DAMAGE_INDEX]}"
SIM_DAMAGE_NAME="$(basename "${SIM_DAMAGE_FILE}" .bed)"
OUTPUT_DIR="/cta/users/guneyn23/peak_center_20kb/noUV_closed_alltime_damage_overlaps/simulated"
OUTPUT_FILE="${OUTPUT_DIR}/${SIM_DAMAGE_NAME}_${REGION_NAME}_400windows_overlap.bed"

mkdir -p "${OUTPUT_DIR}"

echo "Array task: ${SLURM_ARRAY_TASK_ID}"
echo "Closed region: ${REGION_NAME}"
echo "Window file: ${WINDOW_FILE}"
echo "Simulated damage file: ${SIM_DAMAGE_FILE}"
echo "Output file: ${OUTPUT_FILE}"

bedtools intersect \
    -a "${WINDOW_FILE}" \
    -b "${SIM_DAMAGE_FILE}" \
    -wa \
    -F 0.51 \
    -c \
    > "${OUTPUT_FILE}"

echo "Job finished"
date
