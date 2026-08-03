#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=fold_baseline_normalize
#SBATCH --output=/cta/users/guneyn23/rpkm/fold_baseline_normalize_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/fold_baseline_normalize_%j.err
#SBATCH --mem=8G





echo "Job started"
date


source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env


SCRIPT="/cta/users/guneyn23/rpkm/fold_baseline_plot.py"


echo "Processing 6-4PP data"

python "${SCRIPT}" \
    /cta/users/guneyn23/rpkm/64_rpkm/ATAC_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/H3K9me3_mean_normalized_rpkm.tsv\
    /cta/users/guneyn23/rpkm/64_rpkm/H3K27me3_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/64_folded_baseline_normalized6_10.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/64_folded_baseline_normalized6_10.png \
    "6-4PP Damage Enrichment by Distance From Peak Center"


echo "Processing CPD data"

python "${SCRIPT}" \
    /cta/users/guneyn23/rpkm/CPD_rpkm/atac_rpkm/mean_rpkm_ratio.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/close_rpkm/H3K9me3_mean_rpkm_ratio.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/close_rpkm/H3K27me3_mean_rpkm_ratio.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/CPD_folded_baseline_normalized6_10.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/CPD_folded_baseline_normalized6_10.png \
    "CPD Damage Enrichment by Distance From Peak Center"


echo "Both analyses completed successfully"
date