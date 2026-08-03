#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=macs3_peak
#SBATCH --output=/cta/users/guneyn23/macs3_peakcalling/macs3_%j.out
#SBATCH --error=/cta/users/guneyn23/macs3_peakcalling/macs3_%j.err
#SBATCH --mem=16G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate macs3

OUTPUT_DIR="/cta/users/guneyn23/macs3_peakcalling"

macs3 callpeak \
  -f BAMPE \
  -t /cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam \
  -g hs \
  -n HelanoUV_R1_ATAC \
  -B \
  -q 0.01 \
  --outdir "$OUTPUT_DIR"

echo "Job finished:"
date
