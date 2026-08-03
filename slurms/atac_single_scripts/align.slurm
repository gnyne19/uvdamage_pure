#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=bt2_align_uv
#SBATCH --output=/cta/users/guneyn23/bowtie2_alignment/bt2_align_uv_%j.out
#SBATCH --error=/cta/users/guneyn23/bowtie2_alignment/bt2_align_uv_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

bowtie2 \
  -p 16 \
  -x /cta/users/guneyn23/reference_genome/bowtie2_index/genome_hg38 \
  --local \
  --very-sensitive \
  --no-mixed \
  --no-discordant \
  -I 25 \
  -X 700 \
  --seed 42 \
  -1 /cta/users/guneyn23/trimmed_fastq/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_1.trimmed.dedup.fastq.gz \
  -2 /cta/users/guneyn23/trimmed_fastq/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_2.trimmed.dedup.fastq.gz \
  -S /cta/users/guneyn23/bowtie2_alignment/HelanoUV_R1_ATAC.sam

echo "Job finished:"
date
