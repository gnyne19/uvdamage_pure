#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=bt2_index_hg38
#SBATCH --output=/cta/users/guneyn23/reference_genome/bowtie2_index/bt2_index_hg38_%j.out
#SBATCH --error=/cta/users/guneyn23/reference_genome/bowtie2_index/bt2_index_hg38_%j.err
#SBATCH --mem=48G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq



bowtie2-build \
  --threads 16 \
  /cta/users/guneyn23/reference_genome/genome_hg38.fa \
  /cta/users/guneyn23/reference_genome/bowtie2_index/genome_hg38

echo "Job finished:"
date
