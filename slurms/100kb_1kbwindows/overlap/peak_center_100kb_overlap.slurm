#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=peak_center_100kb_overlap
#SBATCH --array=0-11
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/overlaps/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/overlaps/logs/overlap_%A_%a.err
#SBATCH --mem=16G

set -euo pipefail

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

OUTPUT_DIR="/cta/users/guneyn23/peak_center_100kb/overlaps"

WINDOW_FILES=(
    "/cta/users/guneyn23/peak_center_100kb/ATAC_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/ATAC_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/ATAC_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/ATAC_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K27me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K27me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K27me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K27me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K9me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K9me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K9me3_100windows_1kb.bed"
    "/cta/users/guneyn23/peak_center_100kb/H3K9me3_100windows_1kb.bed"
)

DAMAGE_FILES=(
    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed"
)

OUTPUT_NAMES=(
    "ATAC_64_real_overlap.bed"
    "ATAC_64_simulated_overlap.bed"
    "ATAC_CPD_real_overlap.bed"
    "ATAC_CPD_simulated_overlap.bed"
    "H3K27me3_64_real_overlap.bed"
    "H3K27me3_64_simulated_overlap.bed"
    "H3K27me3_CPD_real_overlap.bed"
    "H3K27me3_CPD_simulated_overlap.bed"
    "H3K9me3_64_real_overlap.bed"
    "H3K9me3_64_simulated_overlap.bed"
    "H3K9me3_CPD_real_overlap.bed"
    "H3K9me3_CPD_simulated_overlap.bed"
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
