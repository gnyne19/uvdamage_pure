#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=diffbind_250_nfr
#SBATCH --array=0-1
#SBATCH --mem=200G
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/all_contrasts_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/all_contrasts_%A_%a.err

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate diffbind

REPO_ROOT="${REPO_ROOT:-/cta/users/guneyn23/uvdamage_pure}"

SCRIPTS=(
    "${REPO_ROOT}/scripts/diffbind/summit_based/diffbind_250.R"
    "${REPO_ROOT}/scripts/diffbind/nucleosome_free/diffbind_nucleosome_free.R"
)

SCRIPT="${SCRIPTS[$SLURM_ARRAY_TASK_ID]}"

echo "Final DiffBind analysis started (250-bp summit and NFR)"
echo "Script: $SCRIPT"
date

Rscript "$SCRIPT"

echo "Final DiffBind analysis completed"
date
