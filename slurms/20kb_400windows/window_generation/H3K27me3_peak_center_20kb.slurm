#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=close_peak_center
#SBATCH --output=/cta/users/guneyn23/close_peak_center_20kb/H3K27me3_peak_center_%j.out
#SBATCH --error=/cta/users/guneyn23/close_peak_center_20kb/H3K27me3_peak_center_%j.err
#SBATCH --mem=8G

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

python /cta/users/guneyn23/close_peak_center_20kb/close_peak_center.py \
    /cta/users/guneyn23/encode/ENCFF584RYA.bed \
    /cta/users/guneyn23/close_peak_center_20kb/H3K27me3_summit_center_20kb.bed

bedtools makewindows \
    -b /cta/users/guneyn23/close_peak_center_20kb/H3K27me3_summit_center_20kb.bed \
    -n 400 \
    -i srcwinnum \
    > /cta/users/guneyn23/close_peak_center_20kb/H3K27me3_400_center_windows.bed

echo "Job completed"
date