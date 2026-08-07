#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=relative_100kb_filtered
#SBATCH --mem=4G
#SBATCH --output=/cta/users/guneyn23/positive_relative/100kb/logs/filtered_100kb_%j.out
#SBATCH --error=/cta/users/guneyn23/positive_relative/100kb/logs/filtered_100kb_%j.err

set -e

echo "100 kb filtered positive relative plots are being created"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/positive_relative/positive_relative_filtered_plots.py \
  --resolution 100

echo "100 kb filtered positive relative plots completed"
date
