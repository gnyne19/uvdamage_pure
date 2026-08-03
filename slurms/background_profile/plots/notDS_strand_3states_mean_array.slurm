#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_strand_mean_array
#SBATCH --array=0-71
#SBATCH --mem=2G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/mean_array_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/mean_array_%A_%a.err

set -euo pipefail

BASE="/cta/users/guneyn23"
RPKM_DIR="${BASE}/peak_center_20kb/notDS_strand_3states/rpkm"
PART_DIR="${BASE}/peak_center_20kb/notDS_strand_3states/mean_parts"
REGIONS=("ATAC" "H3K9me3" "H3K27me3")
STRANDS=("plus" "minus")
TIMES=("1m" "15m" "30m" "1h" "4h" "8h" "1m" "15m" "30m" "1h" "4h" "8h")
DAMAGES=("64" "64" "64" "64" "64" "64" "CPD" "CPD" "CPD" "CPD" "CPD" "CPD")
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

REGION_INDEX=$((SLURM_ARRAY_TASK_ID / 24))
WITHIN_REGION=$((SLURM_ARRAY_TASK_ID % 24))
STRAND_INDEX=$((WITHIN_REGION / 12))
SAMPLE_INDEX=$((WITHIN_REGION % 12))
REGION="${REGIONS[$REGION_INDEX]}"
STRAND="${STRANDS[$STRAND_INDEX]}"
SAMPLE="${SAMPLES[$SAMPLE_INDEX]}"
TIME="${TIMES[$SAMPLE_INDEX]}"
DAMAGE="${DAMAGES[$SAMPLE_INDEX]}"
INPUT="${RPKM_DIR}/${SAMPLE}_notDS_${STRAND}_${REGION}_400windows_rpkm.bed"
OUTPUT="${PART_DIR}/${REGION}_${DAMAGE}_${TIME}_${STRAND}_mean.tsv"
TEMP="${OUTPUT}.tmp.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}"

mkdir -p "${PART_DIR}"
[[ -s "${INPUT}" ]] || { echo "Missing RPKM: ${INPUT}" >&2; exit 1; }
trap 'rm -f "${TEMP}"' EXIT

LC_ALL=C awk -F $'\t' \
    -v region="${REGION}" -v damage="${DAMAGE}" \
    -v time="${TIME}" -v strand="${STRAND}" '
    BEGIN {
        OFS="\t"
        print "region","damage","time","strand","window","distance_kb","n_peaks","mean_rpkm"
    }
    {
        parts_n=split($4, parts, "_")
        window=parts[parts_n]+0
        if (window < 1 || window > 400) {
            printf "Invalid window at line %d: %s\n", NR, $4 > "/dev/stderr"
            exit 1
        }
        count[window]++
        sum[window]+=$NF
    }
    END {
        if (NR == 0) exit 1
        for (window=1; window<=400; window++) {
            if (count[window] == 0) {
                printf "Missing window: %d\n", window > "/dev/stderr"
                exit 1
            }
            distance=-10+(window-0.5)*0.05
            print region,damage,time,strand,window,distance,count[window],sum[window]/count[window]
        }
    }
' "${INPUT}" > "${TEMP}"

mv "${TEMP}" "${OUTPUT}"
trap - EXIT
echo "Saved: ${OUTPUT}"

