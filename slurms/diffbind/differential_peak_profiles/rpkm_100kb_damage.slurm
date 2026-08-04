#!/bin/bash
#SBATCH --account=users
#SBATCH --partition=mid_mdbf
#SBATCH --qos=mid_mdbf
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --array=0-95
#SBATCH --job-name=diff_100kb_rpkm
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/peak_100kb_rpkm_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/peak_100kb_rpkm_%A_%a.err

set -euo pipefail

BASE_DIR="/cta/users/guneyn23/diffbind/no_summits/differential_peak_center_100kb_100windows"
OVERLAP_DIR="${BASE_DIR}/overlaps"
OUTPUT_DIR="${BASE_DIR}/rpkm"
PYTHON="/cta/users/guneyn23/miniconda3/envs/plot_env/bin/python"
RPKM_SCRIPT="/cta/users/guneyn23/diffbind/no_summits/calculate_peak_center_rpkm.py"

mkdir -p "$OUTPUT_DIR"

WINDOW_FILES=(
    "no_summits_noUV_vs_UV_4h_DESeq2_noUV_higher_FDR005_100windows.bed"
    "no_summits_noUV_vs_UV_4h_DESeq2_UV_4h_higher_FDR005_100windows.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_noUV_higher_FDR005_100windows.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_UV_8h_higher_FDR005_100windows.bed"
)

mapfile -t REAL_DAMAGE_FILES < <(
    find /cta/users/guneyn23/damageseq_data \
        -maxdepth 1 -type f -name 'R3Hela_*_DS.bed' | sort
)
mapfile -t SIMULATED_DAMAGE_FILES < <(
    find /cta/users/guneyn23/damageseq_data/simulation \
        -maxdepth 1 -type f -name 'R3Hela_*_DS_sim.bed' | sort
)
DAMAGE_FILES=("${REAL_DAMAGE_FILES[@]}" "${SIMULATED_DAMAGE_FILES[@]}")

[[ ${#DAMAGE_FILES[@]} -eq 24 ]] || {
    echo "Expected 24 damage files, found ${#DAMAGE_FILES[@]}" >&2
    exit 1
}

WINDOW_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
DAMAGE_INDEX=$((SLURM_ARRAY_TASK_ID % 24))

WINDOW_NAME="${WINDOW_FILES[$WINDOW_INDEX]%.bed}"
DAMAGE_FILE="${DAMAGE_FILES[$DAMAGE_INDEX]}"
DAMAGE_NAME="$(basename "$DAMAGE_FILE" .bed)"
OVERLAP_FILE="${OVERLAP_DIR}/${DAMAGE_NAME}_${WINDOW_NAME}_overlap.bed"
OUTPUT_FILE="${OUTPUT_DIR}/${DAMAGE_NAME}_${WINDOW_NAME}_rpkm.bed"

[[ -s "$OVERLAP_FILE" ]] || { echo "Missing overlap file: $OVERLAP_FILE" >&2; exit 1; }

"$PYTHON" "$RPKM_SCRIPT" \
    "$OVERLAP_FILE" \
    "$DAMAGE_FILE" \
    "$OUTPUT_FILE"
