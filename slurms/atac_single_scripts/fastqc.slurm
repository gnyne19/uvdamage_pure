#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=fastqc_helanouv
#SBATCH --output=fastqc_%j.out
#SBATCH --error=fastqc_%j.err
#SBATCH --mem=16G

echo "Job started:"
date

# Conda kullanıyorsan:
source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq



fastqc \
  -t 16 \
  -o fastqc_results \
  /cta/users/guneyn23/atacdata/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_1.fastq.gz\
  /cta/users/guneyn23/atacdata/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_2.fastq.gz

echo "Job finished:"
date
