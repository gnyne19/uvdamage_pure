#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=macs2_peak
#SBATCH --output=/cta/users/guneyn23/macs2_peakcalling/macs2_%j.out
#SBATCH --error=/cta/users/guneyn23/macs2_peakcalling/macs2_%j.err
#SBATCH --mem=16G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate macs2

OUTPUT_DIR="/cta/users/guneyn23/macs2_peakcalling"


macs2 callpeak \
  -t /cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam \
  -f BAMPE \
  --nomodel \
  --shift -100 \
  --extsize 200 \
  -g 2701495711 \
  --keep-dup all \
  -q 0.05 \
  -n HelanoUV_R1_ATAC_MACS2 \
  --outdir "$OUTPUT_DIR"

echo "Job finished:"
date
