#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=hmmratac
#SBATCH --output=/cta/users/guneyn23/macs3_peakcalling/hmmratac/hmmratac_%j.out
#SBATCH --error=/cta/users/guneyn23/macs3_peakcalling/hmmratac/hmmratac_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate macs3

OUTPUT_DIR="/cta/users/guneyn23/macs3_peakcalling/hmmratac"


cd "$OUTPUT_DIR"

macs3 hmmratac \
  -i /cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam \
  -f BAMPE \
  -n HelanoUV_R1_ATAC
  --outdir /cta/users/guneyn23/macs3_peakcalling/hmmratac
echo "Job finished:"
date