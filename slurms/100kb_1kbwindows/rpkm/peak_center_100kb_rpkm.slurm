#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=rpkm_100kb
#SBATCH --array=0-11
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/rpkm/logs/rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/rpkm/logs/rpkm_%A_%a.err
#SBATCH --mem=16G

set -e

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

OVERLAP_DIR="/cta/users/guneyn23/peak_center_100kb/overlaps"
OUTPUT_DIR="/cta/users/guneyn23/peak_center_100kb/rpkm"
RPKM_SCRIPT="/cta/users/guneyn23/peak_center_100kb/rpkm/calculate_rpkm.py"

OVERLAP_FILES=(
    "${OVERLAP_DIR}/ATAC_64_real_overlap.bed"
    "${OVERLAP_DIR}/ATAC_64_simulated_overlap.bed"
    "${OVERLAP_DIR}/ATAC_CPD_real_overlap.bed"
    "${OVERLAP_DIR}/ATAC_CPD_simulated_overlap.bed"
    "${OVERLAP_DIR}/H3K27me3_64_real_overlap.bed"
    "${OVERLAP_DIR}/H3K27me3_64_simulated_overlap.bed"
    "${OVERLAP_DIR}/H3K27me3_CPD_real_overlap.bed"
    "${OVERLAP_DIR}/H3K27me3_CPD_simulated_overlap.bed"
    "${OVERLAP_DIR}/H3K9me3_64_real_overlap.bed"
    "${OVERLAP_DIR}/H3K9me3_64_simulated_overlap.bed"
    "${OVERLAP_DIR}/H3K9me3_CPD_real_overlap.bed"
    "${OVERLAP_DIR}/H3K9me3_CPD_simulated_overlap.bed"
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
    "ATAC_64_real_rpkm.bed"
    "ATAC_64_simulated_rpkm.bed"
    "ATAC_CPD_real_rpkm.bed"
    "ATAC_CPD_simulated_rpkm.bed"
    "H3K27me3_64_real_rpkm.bed"
    "H3K27me3_64_simulated_rpkm.bed"
    "H3K27me3_CPD_real_rpkm.bed"
    "H3K27me3_CPD_simulated_rpkm.bed"
    "H3K9me3_64_real_rpkm.bed"
    "H3K9me3_64_simulated_rpkm.bed"
    "H3K9me3_CPD_real_rpkm.bed"
    "H3K9me3_CPD_simulated_rpkm.bed"
)

OVERLAP_FILE="${OVERLAP_FILES[$SLURM_ARRAY_TASK_ID]}"
DAMAGE_FILE="${DAMAGE_FILES[$SLURM_ARRAY_TASK_ID]}"
RPKM_FILE="${OUTPUT_DIR}/${OUTPUT_NAMES[$SLURM_ARRAY_TASK_ID]}"

echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Overlap file: ${OVERLAP_FILE}"
echo "Damage file: ${DAMAGE_FILE}"
echo "RPKM output: ${RPKM_FILE}"

python "${RPKM_SCRIPT}" \
    "${OVERLAP_FILE}" \
    "${DAMAGE_FILE}" \
    "${RPKM_FILE}"

echo "Task completed successfully"
date
