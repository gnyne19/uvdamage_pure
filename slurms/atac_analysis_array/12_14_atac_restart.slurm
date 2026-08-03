#!/bin/bash

#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --qos=long_mdbf
#SBATCH --partition=long_mdbf
#SBATCH --job-name=atac_12_14
#SBATCH --array=0-12
#SBATCH --output=/cta/users/guneyn23/atac_pipeline_logs/restart2_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/atac_pipeline_logs/restart2_%A_%a.err
#SBATCH --mem=128G


set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh

SAMPLES=(
    "Hela_1h_R1_ATAC"
    "Hela_1h_R3_ATAC"
    "Hela_1m_R1_ATAC"
    "Hela_1m_R3_ATAC"
    "Hela_4h_R1_ATAC"
    "Hela_4h_R3_ATAC"
    "Hela_8h_R1_ATAC"
    "Hela_8h_R3_ATAC"
    "Hela_15m_R1_ATAC"
    "Hela_15m_R3_ATAC"
    "Hela_30m_R1_ATAC"
    "Hela_30m_R3_ATAC"
    "HelanoUV_R3_ATAC"
)

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"

BASE_DIR="/cta/users/guneyn23/atacseq_results"
SAMPLE_DIR="${BASE_DIR}/${SAMPLE}"

FINAL_BAM="${SAMPLE_DIR}/07_final_bam/${SAMPLE}.filtered.noMT.noBlacklist.bam"

BAMQC_DIR="${SAMPLE_DIR}/09_bamqc"
SHIFT_DIR="${SAMPLE_DIR}/10_shift_split"
TSS_DIR="${SAMPLE_DIR}/11_tss_enrichment"
BIGWIG_DIR="${SAMPLE_DIR}/12_bigwig"
PEAK_DIR="${SAMPLE_DIR}/13_macs3_peaks"
SHIFTED_BAM="${SHIFT_DIR}/${SAMPLE}.shifted.bam"
NFR_BAM="${SHIFT_DIR}/${SAMPLE}.NucleosomeFree.bam"

mkdir -p \
    "$BAMQC_DIR" \
    "$SHIFT_DIR" \
    "$TSS_DIR" \
    "$BIGWIG_DIR" \
    "$PEAK_DIR"

echo "Job started."
echo "Array job ID: ${SLURM_ARRAY_JOB_ID}"
echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Current sample: $SAMPLE"
echo "Final BAM: $FINAL_BAM"
date


echo ""
echo "12/14 — TSS enrichment analysis started."
date

conda deactivate
conda activate atacseqqc

Rscript /cta/users/guneyn23/tss_enrichment_score/tss_enrichment_score_array.R \
    "$SHIFTED_BAM" \
    "$SAMPLE" \
    "$TSS_DIR"

if [[ ! -s "${TSS_DIR}/${SAMPLE}.TSS_enrichment_score.tsv" ]]; then
    echo "ERROR: TSS enrichment score file was not created:"
    echo "${TSS_DIR}/${SAMPLE}.TSS_enrichment_score.tsv"
    exit 1
fi

echo "TSS enrichment analysis finished."


echo ""
echo "13/14 — BigWig generation started."
date

conda deactivate
conda activate atacseqqc

# Generate a BigWig file using all shifted ATAC-seq fragments.
bamCoverage \
    --bam "$SHIFTED_BAM" \
    --outFileName "${BIGWIG_DIR}/${SAMPLE}.shifted.RPGC.bw" \
    --binSize 10 \
    --normalizeUsing RPGC \
    --effectiveGenomeSize 2701495711 \
    --numberOfProcessors "$SLURM_CPUS_PER_TASK"

# Generate a BigWig file using nucleosome-free fragments only.
bamCoverage \
    --bam "$NFR_BAM" \
    --outFileName "${BIGWIG_DIR}/${SAMPLE}.NucleosomeFree.RPGC.bw" \
    --binSize 10 \
    --normalizeUsing RPGC \
    --effectiveGenomeSize 2701495711 \
    --numberOfProcessors "$SLURM_CPUS_PER_TASK"

if [[ ! -s "${BIGWIG_DIR}/${SAMPLE}.shifted.RPGC.bw" ]]; then
    echo "ERROR: Shifted BigWig file was not created."
    exit 1
fi

if [[ ! -s "${BIGWIG_DIR}/${SAMPLE}.NucleosomeFree.RPGC.bw" ]]; then
    echo "ERROR: Nucleosome-free BigWig file was not created."
    exit 1
fi

echo "BigWig generation finished."


echo ""
echo "14/14 — MACS3 peak calling started."
date

conda deactivate
conda activate macs3

macs3 callpeak \
    -t "$FINAL_BAM" \
    -f BAMPE \
    -g hs \
    -n "$SAMPLE" \
    -B \
    -q 0.01 \
    --outdir "$PEAK_DIR"

if [[ ! -s "${PEAK_DIR}/${SAMPLE}_peaks.narrowPeak" ]]; then
    echo "ERROR: MACS3 narrowPeak file was not created."
    exit 1
fi

echo "MACS3 peak calling finished."
echo ""
echo "Removing unnecessary intermediate files."

rm -f \
    "${SAMPLE_DIR}/05_alignment/${SAMPLE}.sam" \
    "${SAMPLE_DIR}/05_alignment/${SAMPLE}.bam" \
    "${SAMPLE_DIR}/06_bam_filter/${SAMPLE}.namesorted.bam" \
    "${SAMPLE_DIR}/06_bam_filter/${SAMPLE}.fixmate.bam" \
    "${SAMPLE_DIR}/06_bam_filter/${SAMPLE}.fixmate.sorted.bam"

echo "Unnecessary intermediate files were removed."

echo ""
echo "All steps completed successfully for sample: $SAMPLE"
date

