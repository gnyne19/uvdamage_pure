#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=mt_blacklist_filter
#SBATCH --output=/cta/users/guneyn23/bam_filter2/mt_blacklist_filter2_%j.out
#SBATCH --error=/cta/users/guneyn23/bam_filter2/mt_blacklist_filter2_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

INPUT_BAM="/cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.filtered.bam"
BLACKLIST="/cta/users/guneyn23/reference_genome/ENCFF356LFX.bed"
OUTPUT_BAM="/cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam"



#
samtools view \
  -@ 16 \
  -b \
  "$INPUT_BAM" \
   $(samtools idxstats "$INPUT_BAM" | cut -f1 | grep -v -E '^chrM$|^MT$|^\*$') |  \
bedtools intersect \
  -v \
  -abam - \
  -b "$BLACKLIST" \
  > "$OUTPUT_BAM"

samtools index \
  -@ 16 \
  "$OUTPUT_BAM"

samtools flagstat \
  "$OUTPUT_BAM" > /cta/users/guneyn23/bam_filter2/flagstat_HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.txt

samtools idxstats \
  "$OUTPUT_BAM" > /cta/users/guneyn23/bam_filter2/idxstats_HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.txt

echo "Job finished:"
date
