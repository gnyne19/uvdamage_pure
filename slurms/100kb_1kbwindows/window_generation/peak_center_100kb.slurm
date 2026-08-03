#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=peak_center_100kb
#SBATCH --array=0-2
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/peak_center_100kb_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/peak_center_100kb_%A_%a.err
#SBATCH --mem=8G

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

INPUT_FILES=(
    "/cta/users/guneyn23/idr_results/HelanoUV_R1_R3_IDR_0.05.narrowPeak"
    "/cta/users/guneyn23/encode/ENCFF872YCK.bed"
    "/cta/users/guneyn23/encode/ENCFF584RYA.bed"
)

NAMES=(
    "ATAC"
    "H3K9me3"
    "H3K27me3"
)

INPUT_FILE="${INPUT_FILES[$SLURM_ARRAY_TASK_ID]}"
NAME="${NAMES[$SLURM_ARRAY_TASK_ID]}"
CENTER_FILE="/cta/users/guneyn23/peak_center_100kb/${NAME}_summit_centered_100kb.bed"
WINDOW_FILE="/cta/users/guneyn23/peak_center_100kb/${NAME}_100windows_1kb.bed"

python /cta/users/guneyn23/peak_center_100kb/peak_center_100kb.py \
    "${INPUT_FILE}" \
    "${CENTER_FILE}"

bedtools makewindows \
    -b "${CENTER_FILE}" \
    -n 100 \
    -i srcwinnum \
    > "${WINDOW_FILE}"

echo "Job completed"
date
