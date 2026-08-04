#!/bin/bash
#SBATCH --account=users
#SBATCH --partition=mid_mdbf
#SBATCH --qos=mid_mdbf
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --job-name=diff_hetero_overlap
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/heterochromatin_overlap_%j.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/heterochromatin_overlap_%j.err

set -euo pipefail

DIFF_DIR="/cta/users/guneyn23/diffbind/no_summits"
OUTPUT_DIR="${DIFF_DIR}/heterochromatin_overlap"
BEDTOOLS="/cta/users/guneyn23/miniconda3/envs/atacseq/bin/bedtools"
SUMMARY_FILE="${OUTPUT_DIR}/heterochromatin_overlap_summary.tsv"

mkdir -p "$OUTPUT_DIR"

PEAK_FILES=(
    "no_summits_noUV_vs_UV_4h_DESeq2_noUV_higher_FDR005.bed"
    "no_summits_noUV_vs_UV_4h_DESeq2_UV_4h_higher_FDR005.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_noUV_higher_FDR005.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_UV_8h_higher_FDR005.bed"
)

PEAK_NAMES=(
    "4h_noUV_higher"
    "4h_UV_higher"
    "8h_noUV_higher"
    "8h_UV_higher"
)

MARK_FILES=(
    "/cta/users/guneyn23/encode/ENCFF872YCK.bed"
    "/cta/users/guneyn23/encode/ENCFF584RYA.bed"
)

MARK_NAMES=(
    "H3K9me3"
    "H3K27me3"
)

printf "Peak_group\tMark\tTotal_peaks\tOverlapping_peaks\tNon_overlapping_peaks\tOverlap_percent\n" \
    > "$SUMMARY_FILE"

for peak_index in "${!PEAK_FILES[@]}"; do
    peak_file="${DIFF_DIR}/${PEAK_FILES[$peak_index]}"
    peak_name="${PEAK_NAMES[$peak_index]}"
    total_peaks=$(wc -l < "$peak_file")

    for mark_index in "${!MARK_FILES[@]}"; do
        mark_file="${MARK_FILES[$mark_index]}"
        mark_name="${MARK_NAMES[$mark_index]}"
        overlap_file="${OUTPUT_DIR}/${peak_name}_${mark_name}_overlap.bed"
        non_overlap_file="${OUTPUT_DIR}/${peak_name}_${mark_name}_non_overlap.bed"

        "$BEDTOOLS" intersect \
            -a "$peak_file" \
            -b "$mark_file" \
            -u \
            > "$overlap_file"

        "$BEDTOOLS" intersect \
            -a "$peak_file" \
            -b "$mark_file" \
            -v \
            > "$non_overlap_file"

        overlapping_peaks=$(wc -l < "$overlap_file")
        non_overlapping_peaks=$(wc -l < "$non_overlap_file")
        overlap_percent=$(awk \
            -v overlap="$overlapping_peaks" \
            -v total="$total_peaks" \
            'BEGIN {printf "%.2f", 100 * overlap / total}'
        )

        printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
            "$peak_name" \
            "$mark_name" \
            "$total_peaks" \
            "$overlapping_peaks" \
            "$non_overlapping_peaks" \
            "$overlap_percent" \
            >> "$SUMMARY_FILE"

        echo "Completed: ${peak_name} vs ${mark_name}"
    done
done

echo "Summary: $SUMMARY_FILE"
