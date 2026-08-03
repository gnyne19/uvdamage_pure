#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=peak_center
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/peak_center_%j.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/peak_center_%j.err
#SBATCH --mem=8G


echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

python /cta/users/guneyn23/peak_center_20kb/peak_center_20kb.py

bedtools makewindows \
  -b /cta/users/guneyn23/peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_summit_centered_20kb.bed \
  -n 400 \
  -i srcwinnum \
  > /cta/users/guneyn23/peak_center_20kb/HelanoUV_R1_R3_IDR_0.05_400windows.bed

echo "Job completed"
date
