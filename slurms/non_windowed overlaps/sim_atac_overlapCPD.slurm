#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=atac_sim_overlapCPD
#SBATCH --output=/cta/users/guneyn23/atac_sim_overlap/atac_sim_overlapCPD_%j.out
#SBATCH --error=/cta/users/guneyn23/atac_sim_overlap/atac_sim_overlapCPD_%j.err
#SBATCH --mem=8G


echo "job started"
date
source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq


bedtools intersect \
    -a /cta/users/guneyn23/idr_results/HelanoUV_R1_R3_IDR_0.05.narrowPeak \
    -b /cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_r44_DS_sim.bed \
    -wa \
    -F 0.51 \
    -c \
 >/cta/users/guneyn23/atac_sim_overlap/CPD_sim_overlapping_ATAC_peaks.bed

echo "job finished"
date

