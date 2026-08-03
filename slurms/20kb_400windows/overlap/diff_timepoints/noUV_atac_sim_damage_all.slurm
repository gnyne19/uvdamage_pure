#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=noUV_atac_sim_damage
#SBATCH --array=0-9
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/overlaps/logs/noUV_atac_sim_damage_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/overlaps/logs/noUV_atac_sim_damage_%A_%a.err
#SBATCH --mem=16G

echo "Job started"
date

WINDOW_FILE="/cta/users/guneyn23/peak_center_20kb/atac_peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_400windows.bed"
OUTPUT_DIR="/cta/users/guneyn23/peak_center_20kb/overlaps/noUV_atac_sim_damage_all"

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

SIM_DAMAGE_FILE="${SIM_DAMAGE_FILES[$SLURM_ARRAY_TASK_ID]}"
SIM_DAMAGE_NAME="$(basename "${SIM_DAMAGE_FILE}" .bed)"
OUTPUT_FILE="${OUTPUT_DIR}/${SIM_DAMAGE_NAME}_noUV_ATAC_400windows_overlap.bed"

echo "Array task: ${SLURM_ARRAY_TASK_ID}"
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
