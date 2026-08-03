#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=damage64_overlaps
#SBATCH --array=0-5
#SBATCH --output=/cta/users/guneyn23/damage64_overlaps/logs/damage64_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/damage64_overlaps/logs/damage64_%A_%a.err
#SBATCH --mem=16G



echo "Job started"
date


source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq


OUTPUT_DIR="/cta/users/guneyn23/damage64_overlaps"

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/logs"


WINDOW_FILES=(
    "/cta/users/guneyn23/atac_peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_400windows.bed"
    "/cta/users/guneyn23/atac_peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_400windows.bed"

    "/cta/users/guneyn23/close_peak_center_20kb/H3K27me3_400_center_windows.bed"
    "/cta/users/guneyn23/close_peak_center_20kb/H3K27me3_400_center_windows.bed"

    "/cta/users/guneyn23/close_peak_center_20kb/H3K9me3_400_center_windows.bed"
    "/cta/users/guneyn23/close_peak_center_20kb/H3K9me3_400_center_windows.bed"
)


DAMAGE_FILES=(
    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"

    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"

    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"
)


OUTPUT_NAMES=(
    "ATAC_real_64_overlap.bed"
    "ATAC_simulated_64_overlap.bed"

    "H3K27me3_real_64_overlap.bed"
    "H3K27me3_simulated_64_overlap.bed"

    "H3K9me3_real_64_overlap.bed"
    "H3K9me3_simulated_64_overlap.bed"
)


WINDOW_FILE="${WINDOW_FILES[$SLURM_ARRAY_TASK_ID]}"
DAMAGE_FILE="${DAMAGE_FILES[$SLURM_ARRAY_TASK_ID]}"
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_NAMES[$SLURM_ARRAY_TASK_ID]}"


echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Window file: ${WINDOW_FILE}"
echo "Damage file: ${DAMAGE_FILE}"
echo "Output file: ${OUTPUT_FILE}"


bedtools intersect \
    -a "${WINDOW_FILE}" \
    -b "${DAMAGE_FILE}" \
    -wa \
    -F 0.51 \
    -c \
    > "${OUTPUT_FILE}"



echo "Job completed"
date