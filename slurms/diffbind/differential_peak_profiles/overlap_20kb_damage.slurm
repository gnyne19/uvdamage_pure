#!/bin/bash
#SBATCH --account=users
#SBATCH --partition=mid_mdbf
#SBATCH --qos=mid_mdbf
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --array=0-95
#SBATCH --job-name=diff_peak_overlap
#SBATCH --output=/cta/users/guneyn23/diffbind/logs/peak_overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/diffbind/logs/peak_overlap_%A_%a.err

set -euo pipefail

BASE_DIR="/cta/users/guneyn23/diffbind/no_summits/differential_peak_center_20kb_100windows"
WINDOW_DIR="${BASE_DIR}/windows"
OUTPUT_DIR="${BASE_DIR}/overlaps"
BEDTOOLS="/cta/users/guneyn23/miniconda3/envs/atacseq/bin/bedtools"

mkdir -p "$OUTPUT_DIR"

WINDOW_FILES=(
    "no_summits_noUV_vs_UV_4h_DESeq2_noUV_higher_FDR005_100windows.bed"
    "no_summits_noUV_vs_UV_4h_DESeq2_UV_4h_higher_FDR005_100windows.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_noUV_higher_FDR005_100windows.bed"
    "no_summits_noUV_vs_UV_8h_DESeq2_UV_8h_higher_FDR005_100windows.bed"
)

DAMAGE_FILES=(
    "/cta/users/guneyn23/damageseq_data/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_sim.bed"
    "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_sim.bed"
)

WINDOW_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
DAMAGE_INDEX=$((SLURM_ARRAY_TASK_ID % 24))

WINDOW_FILE="${WINDOW_DIR}/${WINDOW_FILES[$WINDOW_INDEX]}"
DAMAGE_FILE="${DAMAGE_FILES[$DAMAGE_INDEX]}"
WINDOW_NAME="$(basename "$WINDOW_FILE" .bed)"
DAMAGE_NAME="$(basename "$DAMAGE_FILE" .bed)"
OUTPUT_FILE="${OUTPUT_DIR}/${DAMAGE_NAME}_${WINDOW_NAME}_overlap.bed"


"$BEDTOOLS" intersect \
    -a "$WINDOW_FILE" \
    -b "$DAMAGE_FILE" \
    -wa \
    -F 0.51 \
    -c \
    > "$OUTPUT_FILE"

echo "Created: $OUTPUT_FILE"
