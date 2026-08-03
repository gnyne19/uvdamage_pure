#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=damage64_rpkm
#SBATCH --array=0-2
#SBATCH --output=/cta/users/guneyn23/rpkm/64_rpkm/logs/damage64_rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/rpkm/64_rpkm/logs/damage64_rpkm_%A_%a.err
#SBATCH --mem=16G


set -e


echo "Job started"
date


source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env


OVERLAP_DIR="/cta/users/guneyn23/damage64_overlaps"
OUTPUT_DIR="/cta/users/guneyn23/rpkm/64_rpkm"

RPKM_SCRIPT="/cta/users/guneyn23/rpkm/real_sim_rpkm.py"
MEAN_SCRIPT="/cta/users/guneyn23/rpkm/mean_normalized_rpkm.py"


REAL_DAMAGE_FILE="/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"

SIM_DAMAGE_FILE="/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"


mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/logs"


REGION_NAMES=(
    "ATAC"
    "H3K27me3"
    "H3K9me3"
)


REAL_OVERLAP_FILES=(
    "${OVERLAP_DIR}/ATAC_real_64_overlap.bed"
    "${OVERLAP_DIR}/H3K27me3_real_64_overlap.bed"
    "${OVERLAP_DIR}/H3K9me3_real_64_overlap.bed"
)


SIM_OVERLAP_FILES=(
    "${OVERLAP_DIR}/ATAC_simulated_64_overlap.bed"
    "${OVERLAP_DIR}/H3K27me3_simulated_64_overlap.bed"
    "${OVERLAP_DIR}/H3K9me3_simulated_64_overlap.bed"
)


REGION="${REGION_NAMES[$SLURM_ARRAY_TASK_ID]}"

REAL_OVERLAP="${REAL_OVERLAP_FILES[$SLURM_ARRAY_TASK_ID]}"
SIM_OVERLAP="${SIM_OVERLAP_FILES[$SLURM_ARRAY_TASK_ID]}"

REAL_RPKM="${OUTPUT_DIR}/${REGION}_real_64_rpkm.bed"
SIM_RPKM="${OUTPUT_DIR}/${REGION}_simulated_64_rpkm.bed"

MEAN_OUTPUT="${OUTPUT_DIR}/${REGION}_mean_normalized_rpkm.tsv"


echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Region: ${REGION}"

echo "Real overlap file: ${REAL_OVERLAP}"
echo "Simulated overlap file: ${SIM_OVERLAP}"

echo "Real damage file: ${REAL_DAMAGE_FILE}"
echo "Simulated damage file: ${SIM_DAMAGE_FILE}"

echo "Real RPKM output: ${REAL_RPKM}"
echo "Simulated RPKM output: ${SIM_RPKM}"
echo "Mean normalized output: ${MEAN_OUTPUT}"


echo "Step 1: Calculating real and simulated RPKM"

python "${RPKM_SCRIPT}" \
    "${REAL_OVERLAP}" \
    "${SIM_OVERLAP}" \
    "${REAL_DAMAGE_FILE}" \
    "${SIM_DAMAGE_FILE}" \
    "${REAL_RPKM}" \
    "${SIM_RPKM}"


echo "Step 2: Calculating mean normalized RPKM"

python "${MEAN_SCRIPT}" \
    "${REAL_RPKM}" \
    "${SIM_RPKM}" \
    "${MEAN_OUTPUT}"


echo "Task completed successfully"
echo "Region: ${REGION}"
echo "Mean output: ${MEAN_OUTPUT}"

date