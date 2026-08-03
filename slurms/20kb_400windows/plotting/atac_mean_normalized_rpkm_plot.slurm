#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=mean_rpkm_plot
#SBATCH --output=/cta/users/guneyn23/rpkm/mean_rpkm_plot_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/mean_rpkm_plot_%j.err
#SBATCH --mem=4G


echo "Mean RPKM and plotting job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/rpkm/mean_normalized_rpkm_plot.py

echo "Mean RPKM and plotting job completed"
date