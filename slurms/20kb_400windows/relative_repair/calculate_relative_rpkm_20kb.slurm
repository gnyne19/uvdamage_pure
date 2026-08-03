#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=relative_rpkm_20kb
#SBATCH --output=/cta/users/guneyn23/relative_repair/logs/relative_rpkm_%j.out
#SBATCH --error=/cta/users/guneyn23/relative_repair/logs/relative_rpkm_%j.err
#SBATCH --mem=32G

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/peak_center_20kb/rpkm/calculate_relative_rpkm.py
