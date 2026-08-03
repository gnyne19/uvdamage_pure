#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=H3K27me3_mean_rpkm
#SBATCH --output=/cta/users/guneyn23/rpkm/close_rpkm/H3K27me3_mean_rpkm_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/close_rpkm/H3K27me3_mean_rpkm_%j.err
#SBATCH --mem=8G

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/rpkm/close_rpkm/close_mean_normalized_rpkm.py \
    /cta/users/guneyn23/rpkm/close_rpkm/H3k27me3_real_rpkm.bed \
    /cta/users/guneyn23/rpkm/close_rpkm/H3k27me3_sim_rpkm.bed \
    /cta/users/guneyn23/rpkm/close_rpkm/H3K27me3_mean_rpkm_ratio.tsv 

echo "Job completed"
date