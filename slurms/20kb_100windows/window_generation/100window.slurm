#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=peak_center
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb_100w/peak_center_%j.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb_100w/peak_center_%j.err
#SBATCH --mem=16G


echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq


bedtools makewindows \
  -b /cta/users/guneyn23/peak_center_20kb/atac_peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_summit_centered_20kb.bed \
  -n 100\
  -i srcwinnum \
  > /cta/users/guneyn23/peak_center_20kb_100w/ATAC_100windows.bed


bedtools makewindows \
  -b /cta/users/guneyn23/peak_center_20kb/close_peak_center_20kb/H3K27me3_summit_center_20kb.bed \
  -n 100\
  -i srcwinnum \
  > /cta/users/guneyn23/peak_center_20kb_100w/H3K27me3_100windows.bed

bedtools makewindows \
  -b /cta/users/guneyn23/peak_center_20kb/close_peak_center_20kb/H3K9me3_summit_center_20kb.bed \
  -n 100\
  -i srcwinnum \
  > /cta/users/guneyn23/peak_center_20kb_100w/H3K9me3_100windows.bed


echo "Job completed"
date
