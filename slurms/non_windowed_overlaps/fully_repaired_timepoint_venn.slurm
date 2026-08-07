#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=fully_repaired_beds
#SBATCH --array=0-19
#SBATCH --output=/cta/users/guneyn23/non_windowed/fully_repaired_timepoint_venn/logs/fully_repaired_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/non_windowed/fully_repaired_timepoint_venn/logs/fully_repaired_%A_%a.err
#SBATCH --mem=4G

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

BASE="/cta/users/guneyn23"
RELATIVE_DIR="${BASE}/non_windowed/nonwindowed_rpkm/relative_rpkm"
OUTPUT_DIR="${BASE}/non_windowed/fully_repaired_timepoint_venn"

PEAK_SETS=("noUV_IDR_ATAC" "4h_UV_specific" "4h_noUV_specific" "8h_UV_specific" "8h_noUV_specific")
DAMAGES=("CPD" "64")
KINDS=("real" "sim")
TIMES=("15m" "30m" "1h" "4h" "8h")

PEAK_SET="${PEAK_SETS[$((SLURM_ARRAY_TASK_ID / 4))]}"
WITHIN=$((SLURM_ARRAY_TASK_ID % 4))
DAMAGE="${DAMAGES[$((WITHIN / 2))]}"
KIND="${KINDS[$((WITHIN % 2))]}"
TASK_DIR="${OUTPUT_DIR}/${PEAK_SET}/${DAMAGE}/${KIND}"
mkdir -p "${TASK_DIR}" "${OUTPUT_DIR}/logs"

for TIME in "${TIMES[@]}"; do
    INPUT="${RELATIVE_DIR}/${PEAK_SET}__${DAMAGE}__${TIME}__${KIND}_relative_rpkm.tsv"
    OUTPUT="${TASK_DIR}/${TIME}_fully_repaired.bed"
    if [[ ! -s "${INPUT}" ]]; then
        echo "Missing or empty relative RPKM file: ${INPUT}" >&2
        exit 1
    fi
    awk -F '\t' 'BEGIN {OFS="\t"} ($NF + 0) == 1 {print $1, $2, $3}' "${INPUT}" \
        | sort -k1,1 -k2,2n -k3,3n -u > "${OUTPUT}"
done

PAIRS=("15m 30m" "15m 1h" "30m 1h" "1h 4h" "1h 8h" "4h 8h")
for PAIR in "${PAIRS[@]}"; do
    read -r LEFT RIGHT <<< "${PAIR}"
    bedtools intersect \
        -a "${TASK_DIR}/${LEFT}_fully_repaired.bed" \
        -b "${TASK_DIR}/${RIGHT}_fully_repaired.bed" \
        -f 1 -F 1 -u \
        > "${TASK_DIR}/${LEFT}_in_${RIGHT}_reciprocal_full_overlap.bed"
done

echo "Completed: ${PEAK_SET} ${DAMAGE} ${KIND}"
