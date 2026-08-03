#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=combined_rpkm_plot
#SBATCH --output=/cta/users/guneyn23/rpkm/64_rpkm/logs/combined_rpkm_plot_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/64_rpkm/logs/combined_rpkm_plot_%j.err
#SBATCH --mem=8G

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/rpkm/plot_combined_ratio.py \
    /cta/users/guneyn23/rpkm/64_rpkm/ATAC_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/H3K9me3_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/H3K27me3_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/64_ATAC_H3K9me3_H3K27me3_mean_rpkm_ratio.png

echo "Job completed"
date