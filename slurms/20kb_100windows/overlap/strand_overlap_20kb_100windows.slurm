#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=100w_strand_overlap
#SBATCH --array=0-143
#SBATCH --output=/cta/users/guneyn23/damage_profile_trial_20kb_100windows_strand/overlaps/logs/overlap_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/damage_profile_trial_20kb_100windows_strand/overlaps/logs/overlap_%A_%a.err
#SBATCH --mem=16G

set -euo pipefail

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

BASE=/cta/users/guneyn23
TRIAL_DIR=${BASE}/damage_profile_trial_20kb_100windows_strand
REAL_DAMAGE_DIR=${BASE}/damageseq_data
SIM_DAMAGE_DIR=${BASE}/damageseq_data/simulation

REGIONS=(ATAC H3K9me3 H3K27me3)
WINDOW_FILES=(
    "${BASE}/peak_center_20kb_100w/ATAC_100windows.bed"
    "${BASE}/peak_center_20kb_100w/H3K9me3_100windows.bed"
    "${BASE}/peak_center_20kb_100w/H3K27me3_100windows.bed"
)
STRANDS=(plus minus)
STRAND_SYMBOLS=(+ -)

mapfile -t REAL_DAMAGE_FILES < <(find "${REAL_DAMAGE_DIR}" -maxdepth 1 -type f -name 'R3Hela_*_DS.bed' | sort)
mapfile -t SIM_DAMAGE_FILES < <(find "${SIM_DAMAGE_DIR}" -maxdepth 1 -type f -name 'R3Hela_*_DS_sim.bed' | sort)

if (( ${#REAL_DAMAGE_FILES[@]} != 12 || ${#SIM_DAMAGE_FILES[@]} != 12 )); then
    echo "Expected 12 real and 12 simulated damage BEDs; found ${#REAL_DAMAGE_FILES[@]} and ${#SIM_DAMAGE_FILES[@]}" >&2
    exit 1
fi

DAMAGE_FILES=("${REAL_DAMAGE_FILES[@]}" "${SIM_DAMAGE_FILES[@]}")

# 3 regions x 24 damage files x 2 damage strands = 144 tasks.
REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 48))
WITHIN_REGION=$((SLURM_ARRAY_TASK_ID % 48))
DAMAGE_INDEX=$((WITHIN_REGION / 2))
STRAND_INDEX=$((WITHIN_REGION % 2))

REGION=${REGIONS[$REGION_INDEX]}
WINDOW_FILE=${WINDOW_FILES[$REGION_INDEX]}
DAMAGE_FILE=${DAMAGE_FILES[$DAMAGE_INDEX]}
STRAND=${STRANDS[$STRAND_INDEX]}
STRAND_SYMBOL=${STRAND_SYMBOLS[$STRAND_INDEX]}

DAMAGE_NAME=$(basename "${DAMAGE_FILE}" .bed)
TIME_DAMAGE=${DAMAGE_NAME#R3Hela_}
TIME_DAMAGE=${TIME_DAMAGE%%_*}
if [[ ! ${TIME_DAMAGE} =~ ^(1m|15m|30m|1h|4h|8h)(CPD|64)$ ]]; then
    echo "Could not parse time and damage type from ${DAMAGE_NAME}" >&2
    exit 1
fi
TIME=${BASH_REMATCH[1]}
DAMAGE=${BASH_REMATCH[2]}

if (( DAMAGE_INDEX < 12 )); then
    KIND=real
    OUTPUT_DIR=${TRIAL_DIR}/overlaps/real/${STRAND}
else
    KIND=sim
    OUTPUT_DIR=${TRIAL_DIR}/overlaps/simulated/${STRAND}
fi
OUTPUT_FILE=${OUTPUT_DIR}/${TIME}_${DAMAGE}_${KIND}_${REGION}_${STRAND}_100windows_overlap.bed

mkdir -p "${OUTPUT_DIR}"

echo "Region: ${REGION}"
echo "Damage BED: ${DAMAGE_FILE}"
echo "Damage strand: ${STRAND} (${STRAND_SYMBOL})"
echo "Output: ${OUTPUT_FILE}"

# Windows are unstranded. Filter damage records by BED column 6 first, then
# count the selected damage strand independently in every 200-bp window.
awk -F '\t' -v strand="${STRAND_SYMBOL}" '$6 == strand' "${DAMAGE_FILE}" \
    | bedtools intersect -a "${WINDOW_FILE}" -b stdin -F 0.51 -c \
    > "${OUTPUT_FILE}"

EXPECTED_LINES=$(wc -l < "${WINDOW_FILE}")
OBSERVED_LINES=$(wc -l < "${OUTPUT_FILE}")
if (( OBSERVED_LINES != EXPECTED_LINES )); then
    echo "Output line count ${OBSERVED_LINES} differs from window line count ${EXPECTED_LINES}" >&2
    exit 1
fi

echo "Completed with ${OBSERVED_LINES} window rows"
