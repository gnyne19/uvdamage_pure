#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=simulated_rpkm_plots
#SBATCH --output=/cta/users/guneyn23/rpkm/simulated_rpkm_plots_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/simulated_rpkm_plots_%j.err
#SBATCH --mem=8G


set -e


echo "Job started"
date


source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env


PLOT_SCRIPT="/cta/users/guneyn23/rpkm/sim_plot_rpkm.py"


echo "Creating the 6-4PP simulated RPKM plot"

python "${PLOT_SCRIPT}" \
    /cta/users/guneyn23/rpkm/64_rpkm/ATAC_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/H3K9me3_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/H3K27me3_mean_normalized_rpkm.tsv \
    /cta/users/guneyn23/rpkm/64_rpkm/64_simulated_rpkm.png \
    "Simulated 6-4PP Damage Distribution Around Peak Centers"


echo "Creating the CPD simulated RPKM plot"

python "${PLOT_SCRIPT}" \
    /cta/users/guneyn23/rpkm/CPD_rpkm/atac_rpkm/mean_rpkm_ratio.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/close_rpkm/H3K9me3_mean_rpkm_ratio.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/close_rpkm/H3K27me3_mean_rpkm_ratio.tsv \
    /cta/users/guneyn23/rpkm/CPD_rpkm/CPD_simulated_rpkm.png \
    "Simulated CPD Damage Distribution Around Peak Centers"


echo "Both plots were completed successfully"
date
