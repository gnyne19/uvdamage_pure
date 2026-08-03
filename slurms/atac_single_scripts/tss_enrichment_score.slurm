#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=tss_enrichment_score
#SBATCH --output=/cta/users/guneyn23/tss_enrichment_score/tss_enrichment_score_%j.out
#SBATCH --error=/cta/users/guneyn23/tss_enrichment_score/tss_enrichment_score_%j.err
#SBATCH --mem=64G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseqqc

Rscript /cta/users/guneyn23/tss_enrichment_score/tss_enrichment_score.R

echo "Job finished:"
date