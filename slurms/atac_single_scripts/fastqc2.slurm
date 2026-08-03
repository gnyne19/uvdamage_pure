#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=fastqc2
#SBATCH --output=/cta/users/guneyn23/fastqc_trimmed_results/fastqc2_%j.out
#SBATCH --error=/cta/users/guneyn23/fastqc_trimmed_results/fastqc2_%j.err
#SBATCH --mem=16G
ls /cta/users/guneyn23/trimmed_fastq
echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq


fastqc \
  -t 16 \
  -o /cta/users/guneyn23/fastqc_trimmed_results \
  /cta/users/guneyn23/trimmed_fastq/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_1.trimmed.dedup.fastq.gz \
  /cta/users/guneyn23/trimmed_fastq/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_2.trimmed.dedup.fastq.gz

echo "Job finished:"
date
