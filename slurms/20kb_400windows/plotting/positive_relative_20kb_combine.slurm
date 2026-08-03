#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=relative_20kb_plot
#SBATCH --mem=4G
#SBATCH --output=/cta/users/guneyn23/positive_relative/20kb/logs/combine_20kb_%j.out
#SBATCH --error=/cta/users/guneyn23/positive_relative/20kb/logs/combine_20kb_%j.err

set -e

echo "20 kb positive relative tables and plots are being combined"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/positive_relative/positive_relative_mean_profiles.py \
  --resolution 20 \
  --combine

echo "20 kb positive relative analysis completed"
date
