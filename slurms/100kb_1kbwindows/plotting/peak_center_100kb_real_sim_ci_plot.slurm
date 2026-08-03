#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=real_sim_ci_plot
#SBATCH --array=0-1
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/rpkm/logs/real_sim_ci_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/rpkm/logs/real_sim_ci_%A_%a.err
#SBATCH --mem=16G

set -e

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

DAMAGE_TYPES=(
    "64"
    "CPD"
)

DAMAGE_TYPE="${DAMAGE_TYPES[$SLURM_ARRAY_TASK_ID]}"
INPUT_DIR="/cta/users/guneyn23/peak_center_100kb/rpkm"
OUTPUT_DIR="/cta/users/guneyn23/peak_center_100kb/rpkm/plots"

python /cta/users/guneyn23/peak_center_100kb/rpkm/real_sim_ci_plot.py \
    "${DAMAGE_TYPE}" \
    "${INPUT_DIR}" \
    "${OUTPUT_DIR}"

echo "Job completed"
date
