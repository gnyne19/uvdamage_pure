#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=bam_filter
#SBATCH --output=/cta/users/guneyn23/bam_filter/bam_filter_%j.out
#SBATCH --error=/cta/users/guneyn23/bam_filter/bam_filter_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

SORTED_BAM="/cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.sorted.bam"
MARKDUP_BAM="/cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.markdup.bam"
FILTERED_BAM="/cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.filtered.bam"

IDXSTATS="/cta/users/guneyn23/bam_filter/idxstats_HelanoUV_R1_ATAC.txt"
FLAGSTAT="/cta/users/guneyn23/bam_filter/flagstat_HelanoUV_R1_ATAC.txt"


samtools idxstats \
  "$SORTED_BAM" > "$IDXSTATS"


samtools flagstat \
  "$SORTED_BAM" > "$FLAGSTAT"


samtools sort \
  -@ 16 \
  -n \
  -o /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.namesorted.bam \
  /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.sorted.bam

samtools fixmate \
  -@ 16 \
  -m \
  /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.namesorted.bam \
  /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.fixmate.bam

samtools sort \
  -@ 16 \
  -o /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.fixmate.sorted.bam \
  /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.fixmate.bam

samtools markdup \
  -@ 16 \
  /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.fixmate.sorted.bam \
  /cta/users/guneyn23/bam_filter/HelanoUV_R1_ATAC.markdup.bam

echo "Filtering"
samtools view \
  -@ 16 \
  -b \
  -f 2 \
  -F 1548 \
  -q 30 \
  "$MARKDUP_BAM" > "$FILTERED_BAM"

samtools index \
  -@ 16 \
  "$FILTERED_BAM"

echo "Job finished:"
date