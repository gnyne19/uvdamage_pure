#!/bin/bash
#SBATCH --account=users
#SBATCH --partition=mid_mdbf
#SBATCH --qos=mid_mdbf
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --job-name=diff_peak_windows
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/peak_windows_%j.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/peak_windows_%j.err

set -euo pipefail

INPUT_DIR="/cta/users/guneyn23/diffbind/no_summits"
BASE_DIR="${INPUT_DIR}/differential_peak_center_20kb_100windows"
WINDOW_DIR="${BASE_DIR}/windows"
BEDTOOLS="/cta/users/guneyn23/miniconda3/envs/atacseq/bin/bedtools"

mkdir -p "$WINDOW_DIR"

PEAK_FILES=(
    "no_summits_noUV_vs_UV_4h_DESeq2_noUV_higher_FDR005.bed"
    "no_summits_noUV_vs_UV_4h_DESeq2_UV_4h_higher_FDR005.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_noUV_higher_FDR005.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_UV_8h_higher_FDR005.bed"
)

for peak_file in "${PEAK_FILES[@]}"; do
    peak_name="${peak_file%.bed}"
    centered_file="${WINDOW_DIR}/${peak_name}_centered_20kb.bed"
    window_file="${WINDOW_DIR}/${peak_name}_100windows.bed"

    awk 'BEGIN {OFS="\t"}
        {
            center = int(($2 + $3) / 2)
            start = center - 10000
            end = center + 10000

            if (start < 0) {
                start = 0
                end = 20000
            }

            print $1, start, end, "diff_peak_" NR
        }
    ' "${INPUT_DIR}/${peak_file}" > "$centered_file"

    "$BEDTOOLS" makewindows \
        -b "$centered_file" \
        -n 100 \
        -i srcwinnum \
        > "$window_file"

    echo "Created: $window_file"
done
