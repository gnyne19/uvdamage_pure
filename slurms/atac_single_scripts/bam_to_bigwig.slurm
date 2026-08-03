#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=bamcoverage
#SBATCH --output=/cta/users/guneyn23/bam_to_bigwig/bamcoverage_%j.out
#SBATCH --error=/cta/users/guneyn23/bam_to_bigwig/bamcoverage_%j.err
#SBATCH --mem=16G


echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate deeptools_env
echo "shifted to bigwig"

bamCoverage \
  --bam /cta/users/guneyn23/bam_qc/split_shift_output/HelanoUV_R1_ATAC.shifted.bam \
  --outFileName /cta/users/guneyn23/bam_to_bigwig/HelanoUV_R1_ATAC.RPGC.bw \
  --binSize 10 \
  --normalizeUsing RPGC \
  --effectiveGenomeSize 2701495711 \
  --numberOfProcessors 4
  echo "NFR to bigwig"

  bamCoverage \
  --bam /cta/users/guneyn23/bam_qc/split_shift_output/NucleosomeFree.bam \
  --outFileName /cta/users/guneyn23/bam_to_bigwig/NucleosomeFree.RPGC.bw \
  --binSize 10 \
  --normalizeUsing RPGC \
  --effectiveGenomeSize 2701495711 \
  --numberOfProcessors 4

echo "Job finished:"
date