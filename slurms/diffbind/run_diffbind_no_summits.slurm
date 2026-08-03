#!/bin/bash
#SBATCH --account=adelab
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --qos=adelab
#SBATCH --partition=genomics
#SBATCH --job-name=diffbind_no_summits
#SBATCH --mem=256G
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/no_summits_%j.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/no_summits_%j.err

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate diffbind

REPO_ROOT="${REPO_ROOT:-/cta/users/guneyn23/uvdamage_pure}"

echo "DiffBind no-summits analysis started"
echo "Job ID: $SLURM_JOB_ID"
echo "CPUs: $SLURM_CPUS_PER_TASK"
date

Rscript "${REPO_ROOT}/scripts/diffbind/summit_based/diffbind_no_summits.R"

echo "DiffBind no-summits analysis completed"
date
