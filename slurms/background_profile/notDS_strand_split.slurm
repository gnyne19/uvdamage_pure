#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_strand_split
#SBATCH --array=0-11
#SBATCH --mem=4G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/split_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/split_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
INPUT_DIR="${BASE}/damageseq_data/notDS"
OUTPUT_DIR="${BASE}/damageseq_data/notDS_strand"
SAMPLES=(
    "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly"
    "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly"
    "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly"
    "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly"
    "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly"
    "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly"
    "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly"
    "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly"
    "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly"
    "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly"
    "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly"
    "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly"
)

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"
INPUT="${INPUT_DIR}/${SAMPLE}_notDS.bed"
PLUS="${OUTPUT_DIR}/${SAMPLE}_notDS_plus.bed"
MINUS="${OUTPUT_DIR}/${SAMPLE}_notDS_minus.bed"
PLUS_TMP="${PLUS}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"
MINUS_TMP="${MINUS}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}"
[[ -s "${INPUT}" ]] || { echo "Missing notDS: ${INPUT}" >&2; exit 1; }
trap 'rm -f "${PLUS_TMP}" "${MINUS_TMP}"' EXIT

LC_ALL=C awk -F $'\t' -v plus="${PLUS_TMP}" -v minus="${MINUS_TMP}" '
    $NF == "+" { print > plus; p++; next }
    $NF == "-" { print > minus; m++; next }
    { bad++ }
    END {
        if (bad) {
            printf "ERROR: %d rows have invalid strand\n", bad > "/dev/stderr"
            exit 1
        }
        printf "plus=%d minus=%d total=%d\n", p, m, p+m
    }
' "${INPUT}"

mv "${PLUS_TMP}" "${PLUS}"
mv "${MINUS_TMP}" "${MINUS}"
trap - EXIT

