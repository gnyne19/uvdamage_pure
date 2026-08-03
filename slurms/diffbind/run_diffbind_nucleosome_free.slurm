#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=long_mdbf
#SBATCH --partition=long_mdbf
#SBATCH --job-name=diffbind_nucfree
#SBATCH --mem=64G
#SBATCH --output=/cta/users/guneyn23/diffbind_nucleosome_free/logs/diffbind_%j.out
#SBATCH --error=/cta/users/guneyn23/diffbind_nucleosome_free/logs/diffbind_%j.err

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate diffbind

cd /cta/users/guneyn23/diffbind_nucleosome_free

echo "Nucleosome-free DiffBind started"
date

Rscript diffbind_nucleosome_free.R

echo "Nucleosome-free DiffBind completed"
date
