#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=macs3_nucfree
#SBATCH --array=0-13
#SBATCH --output=/cta/users/guneyn23/nucleosome_free_peakcalling/logs/macs3_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/nucleosome_free_peakcalling/logs/macs3_%A_%a.err
#SBATCH --mem=16G

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate macs3

SAMPLES=(
    "HelanoUV_R1_ATAC"
    "HelanoUV_R3_ATAC"
    "Hela_1m_R1_ATAC"
    "Hela_1m_R3_ATAC"
    "Hela_15m_R1_ATAC"
    "Hela_15m_R3_ATAC"
    "Hela_30m_R1_ATAC"
    "Hela_30m_R3_ATAC"
    "Hela_1h_R1_ATAC"
    "Hela_1h_R3_ATAC"
    "Hela_4h_R1_ATAC"
    "Hela_4h_R3_ATAC"
    "Hela_8h_R1_ATAC"
    "Hela_8h_R3_ATAC"
)

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"

if [[ "$SAMPLE" == "HelanoUV_R1_ATAC" ]]; then
    INPUT_BAM="/cta/users/guneyn23/bam_qc/split_shift_output/NucleosomeFree.bam"
    OUTPUT_DIR="/cta/users/guneyn23/peak_calling/macs3_peakcalling"
else
    INPUT_BAM="/cta/users/guneyn23/atacseq_results/${SAMPLE}/10_shift_split/${SAMPLE}.NucleosomeFree.bam"
    OUTPUT_DIR="/cta/users/guneyn23/atacseq_results/${SAMPLE}/13_macs3_peaks"
fi

if [[ ! -s "$INPUT_BAM" ]]; then
    echo "ERROR: Input BAM not found or empty: $INPUT_BAM" >&2
    exit 1
fi

echo "Job started"
echo "Sample: $SAMPLE"
echo "Input BAM: $INPUT_BAM"
echo "Output directory: $OUTPUT_DIR"
date

macs3 callpeak \
  -f BAMPE \
  -t "$INPUT_BAM" \
  -g hs \
  -n "${SAMPLE}_NucleosomeFree" \
  -B \
  -q 0.01 \
  --outdir "$OUTPUT_DIR"

echo "Job finished"
date
