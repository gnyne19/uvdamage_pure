#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=all_nonwindowed_overlap
#SBATCH --array=0-115
#SBATCH --output=/cta/users/guneyn23/non_windowed/nonwindowed_overlaps/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/non_windowed/nonwindowed_overlaps/logs/overlap_%A_%a.err
#SBATCH --mem=32G

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

BASE="/cta/users/guneyn23"
OUTPUT_DIR="${BASE}/non_windowed/nonwindowed_overlaps"

# noUV IDR ATAC and the four directional DiffBind-specific peak sets.
PEAK_SET_NAMES=(
    "noUV_IDR_ATAC"
    "4h_UV_specific"
    "4h_noUV_specific"
    "8h_UV_specific"
    "8h_noUV_specific"
)

PEAK_FILES=(
    "${BASE}/idr_results/HelanoUV_R1_R3_IDR_0.05.narrowPeak"
    "${BASE}/diffbind/summits_250/directional_results_DESeq2/diffbind_250_noUV_vs_UV_4h_DESeq2_UV_4h_specific_FDR005.bed"
    "${BASE}/diffbind/summits_250/directional_results_DESeq2/diffbind_250_noUV_vs_UV_4h_DESeq2_noUV_specific_FDR005.bed"
    "${BASE}/diffbind/summits_250/directional_results_DESeq2/diffbind_250_noUV_vs_UV_8h_DESeq2_UV_8h_specific_FDR005.bed"
    "${BASE}/diffbind/summits_250/directional_results_DESeq2/diffbind_250_noUV_vs_UV_8h_DESeq2_noUV_specific_FDR005.bed"
)

# Fixed ordering: six CPD followed by six 6-4PP timepoints.
SAMPLES=(
    "1mCPD_GATCAG_S6"
    "15mCPD_TAGCTT_S2"
    "30mCPD_GGCTAC_S8"
    "1hCPD_CTTGTA_S4"
    "4hCPD_AGTCAA_S10"
    "8hCPD_AGTTCC_S12"
    "1m64_CGATGT_S5"
    "15m64_TTAGGC_S1"
    "30m64_TGACCA_S7"
    "1h64_ACAGTG_S3"
    "4h64_GCCAAT_S9"
    "8h64_CAGATC_S11"
)

# noUV IDR ATAC: 20 jobs (1m excluded; five later times x two damages x real/sim).
# Differential sets: 96 jobs (four sets x 12 samples x real/sim).
NO_IDR_1M_SAMPLE_INDICES=(1 2 3 4 5 7 8 9 10 11)

if (( SLURM_ARRAY_TASK_ID < 20 )); then
    PEAK_INDEX=0
    KIND_INDEX=$((SLURM_ARRAY_TASK_ID / 10))
    WITHIN_KIND=$((SLURM_ARRAY_TASK_ID % 10))
    SAMPLE_INDEX="${NO_IDR_1M_SAMPLE_INDICES[$WITHIN_KIND]}"
else
    DIFFERENTIAL_TASK=$((SLURM_ARRAY_TASK_ID - 20))
    PEAK_INDEX=$((DIFFERENTIAL_TASK / 24 + 1))
    DAMAGE_INDEX=$((DIFFERENTIAL_TASK % 24))
    KIND_INDEX=$((DAMAGE_INDEX / 12))
    SAMPLE_INDEX=$((DAMAGE_INDEX % 12))
fi

PEAK_SET="${PEAK_SET_NAMES[$PEAK_INDEX]}"
PEAK_FILE="${PEAK_FILES[$PEAK_INDEX]}"
SAMPLE="${SAMPLES[$SAMPLE_INDEX]}"

if (( KIND_INDEX == 0 )); then
    KIND="real"
    DAMAGE_FILE="${BASE}/damageseq_data/R3Hela_${SAMPLE}_hg38_primary_assembly_DS.bed"
else
    KIND="sim"
    DAMAGE_FILE="${BASE}/damageseq_data/simulation/R3Hela_${SAMPLE}_hg38_primary_assembly_DS_sim.bed"
fi

# Every BED is written directly into this one folder.
OUTPUT_FILE="${OUTPUT_DIR}/${PEAK_SET}__${SAMPLE}__${KIND}_overlap.bed"

if [[ ! -s "${PEAK_FILE}" ]]; then
    echo "Missing or empty peak file: ${PEAK_FILE}" >&2
    exit 1
fi
if [[ ! -s "${DAMAGE_FILE}" ]]; then
    echo "Missing or empty damage file: ${DAMAGE_FILE}" >&2
    exit 1
fi

echo "Array task: ${SLURM_ARRAY_TASK_ID}"
echo "Peak set: ${PEAK_SET}"
echo "Peak file: ${PEAK_FILE}"
echo "Damage kind: ${KIND}"
echo "Damage file: ${DAMAGE_FILE}"
echo "Output: ${OUTPUT_FILE}"

bedtools intersect \
    -a "${PEAK_FILE}" \
    -b "${DAMAGE_FILE}" \
    -wa \
    -F 0.51 \
    -c \
    > "${OUTPUT_FILE}"

EXPECTED_PEAKS=$(awk 'END {print NR}' "${PEAK_FILE}")
OBSERVED_PEAKS=$(awk 'END {print NR}' "${OUTPUT_FILE}")
if [[ "${OBSERVED_PEAKS}" -ne "${EXPECTED_PEAKS}" ]]; then
    echo "Row-count mismatch: expected ${EXPECTED_PEAKS}, observed ${OBSERVED_PEAKS}" >&2
    exit 1
fi

echo "Completed ${OBSERVED_PEAKS} peaks"
