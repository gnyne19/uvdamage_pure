#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=diffbind_post
#SBATCH --array=0-1
#SBATCH --mem=128G
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/postprocess_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/postprocess_%A_%a.err

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate diffbind

SCRIPTS=(
    "/cta/users/guneyn23/diffbind/split_250_deseq2_beds.R"
    "/cta/users/guneyn23/diffbind_nucleosome_free/postprocess_nfr_deseq2.R"
)

SCRIPT="${SCRIPTS[$SLURM_ARRAY_TASK_ID]}"

echo "DiffBind post-processing started: $SCRIPT"
date

Rscript "$SCRIPT"

echo "DiffBind post-processing completed: $SCRIPT"
date
