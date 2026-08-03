#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=sam_to_bam
#SBATCH --output=/cta/users/guneyn23/bowtie2_alignment/sam_to_bam_%j.out
#SBATCH --error=/cta/users/guneyn23/bowtie2_alignment/sam_to_bam_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

samtools view -@ 16 -bS \
  /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.sam \
  -o /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.bam

samtools sort -@ 16 \
  /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.bam \
  -o /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.sorted.bam

samtools index \
  /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.sorted.bam

echo "Job finished:"
date