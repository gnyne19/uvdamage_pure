#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=H3K27me3_sim_overlapCPD
#SBATCH --output=/cta/users/guneyn23/close_peak_center_20kb/overlaps/H3K27me3_sim_overlapCPD_%j.out
#SBATCH --error=/cta/users/guneyn23/close_peak_center_20kb/overlaps/H3K27me3_sim_overlapCPD_%j.err
#SBATCH --mem=8G


echo "job started"
date


bedtools intersect \
    -a /cta/users/guneyn23/close_peak_center_20kb/H3K27me3_400_center_windows.bed \
    -b /cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed \
    -wa \
    -F 0.51 \
    -c \
 >/cta/users/guneyn23/close_peak_center_20kb/overlaps/CPD_sim_overlapping_H3K27me3__peaks.bed

echo "job finished"
date

