#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=trim_dedup_fastp
#SBATCH --output=/cta/users/guneyn23/fastp_reports/trim_dedup_fastp_%j.out
#SBATCH --error=/cta/users/guneyn23/fastp_reports/trim_dedup_fastp_%j.err
#SBATCH --mem=32G

echo "Job started:"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq



fastp \
  -i /cta/users/guneyn23/atacdata/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_1.fastq.gz \
  -I /cta/users/guneyn23/atacdata/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_2.fastq.gz \
  -o /cta/users/guneyn23/trimmed_fastq/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_1.trimmed.dedup.fastq.gz \
  -O /cta/users/guneyn23/trimmed_fastq/HelanoUV_R1_ATAC_TAAGGCGA-TAGATCGC_S7_combined26_2.trimmed.dedup.fastq.gz \
  --adapter_sequence=CTGTCTCTTATACACATCT \
  --adapter_sequence_r2=CTGTCTCTTATACACATCT \
  --qualified_quality_phred=20\
  --dedup \
  --thread 16 \
  --html /cta/users/guneyn23/fastp_reports/HelanoUV_trim_dedup_fastp.html \
  --json /cta/users/guneyn23/fastp_reports/HelanoUV_trim_dedup_fastp.json
echo "Job finished:"
date