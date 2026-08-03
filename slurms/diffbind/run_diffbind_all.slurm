#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=diffbind_all
#SBATCH --array=0-3
#SBATCH --mem=200G
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/all_contrasts_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/all_contrasts_%A_%a.err

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate diffbind

SCRIPTS=(
    "/cta/users/guneyn23/diffbind/diffbind_75.R"
    "/cta/users/guneyn23/diffbind/diffbind_250.R"
    "/cta/users/guneyn23/diffbind/diffbind_500.R"
    "/cta/users/guneyn23/diffbind_nucleosome_free/diffbind_nucleosome_free.R"
)

SCRIPT="${SCRIPTS[$SLURM_ARRAY_TASK_ID]}"

echo "DiffBind count and contrast job started"
echo "Script: $SCRIPT"
date

Rscript "$SCRIPT"

echo "DiffBind count and contrast job completed"
date
