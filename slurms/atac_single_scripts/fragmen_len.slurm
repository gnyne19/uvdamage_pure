#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=picard_fraglen
#SBATCH --output=/cta/users/guneyn23/bam_qc/picard_fraglen_%j.out
#SBATCH --error=/cta/users/guneyn23/bam_qc/picard_fraglen_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

mkdir -p /cta/users/guneyn23/bam_qc

picard CollectInsertSizeMetrics \
  I=/cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam \
  O=/cta/users/guneyn23/bam_qc/HelanoUV_R1_ATAC.fraglen.stats \
  H=/cta/users/guneyn23/bam_qc/HelanoUV_R1_ATAC.fraglen.pdf \
  M=0.5

echo "Job finished:"
date
