#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=damageseq_notDS
#SBATCH --array=0-11
#SBATCH --mem=24G
#SBATCH --output=/cta/users/guneyn23/damageseq_data/notDS/logs/notDS_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/damageseq_data/notDS/logs/notDS_%A_%a.err

set -euo pipefail

SORTED_DIR="/cta/users/guneyn23/damageseq_data/sorted"
DS_DIR="/cta/users/guneyn23/damageseq_data"
OUTPUT_DIR="/cta/users/guneyn23/damageseq_data/notDS"

SORTED_FILES=(
    "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_sorted_10.bed"
    "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_sorted_10.bed"
)

DS_FILES=(
    "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS.bed"
    "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS.bed"
    "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS.bed"
    "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS.bed"
    "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_DS.bed"
    "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
    "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS.bed"
    "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS.bed"
    "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS.bed"
    "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS.bed"
    "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS.bed"
    "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS.bed"
)

SORTED_NAME="${SORTED_FILES[$SLURM_ARRAY_TASK_ID]}"
DS_NAME="${DS_FILES[$SLURM_ARRAY_TASK_ID]}"

SORTED_FILE="${SORTED_DIR}/${SORTED_NAME}"
DS_FILE="${DS_DIR}/${DS_NAME}"

SAMPLE_NAME="${SORTED_NAME%_sorted_10.bed}"
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}_notDS.bed"
TEMP_FILE="${OUTPUT_FILE}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${OUTPUT_DIR}/logs"



echo "Started: $(date)"
echo "Sorted file: ${SORTED_FILE}"
echo "DS file: ${DS_FILE}"
echo "Output file: ${OUTPUT_FILE}"

# First file: save the DS keys composed of columns 1, 2, 3 and the last column.
# Second file: print a complete sorted-data row only if its key is not in DS.
LC_ALL=C awk -F $'\t' '
    BEGIN {
        OFS = FS
    }

    FNR == NR {
        key = $1 SUBSEP $2 SUBSEP $3 SUBSEP $NF
        ds_keys[key] = 1
        next
    }

    {
        key = $1 SUBSEP $2 SUBSEP $3 SUBSEP $NF
        if (!(key in ds_keys)) {
            print $0
        }
    }
' "${DS_FILE}" "${SORTED_FILE}" > "${TEMP_FILE}"

mv "${TEMP_FILE}" "${OUTPUT_FILE}"
trap - EXIT

SORTED_ROWS=$(wc -l < "${SORTED_FILE}")
DS_ROWS=$(wc -l < "${DS_FILE}")
NOTDS_ROWS=$(wc -l < "${OUTPUT_FILE}")
REMOVED_ROWS=$((SORTED_ROWS - NOTDS_ROWS))

echo "Sorted rows: ${SORTED_ROWS}"
echo "DS rows: ${DS_ROWS}"
echo "Removed matching rows: ${REMOVED_ROWS}"
echo "notDS rows: ${NOTDS_ROWS}"
echo "Completed: $(date)"
