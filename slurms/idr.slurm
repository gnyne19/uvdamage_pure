#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=idr_R1_R3
#SBATCH --output=/cta/users/guneyn23/idr_results/idr_R1_R3_%j.out
#SBATCH --error=/cta/users/guneyn23/idr_results/idr_R1_R3_%j.err
#SBATCH --mem=16G




echo "job started"
date


source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate idr_env

PEAK_R1="/cta/users/guneyn23/peak_calling/macs2_peakcalling/macs3_peakcalling/HelanoUV_R1_ATAC_peaks.narrowPeak"
PEAK_R3="/cta/users/guneyn23/atacseq_results/HelanoUV_R3_ATAC/13_macs3_peaks/HelanoUV_R3_ATAC_peaks.narrowPeak"


OUTPUT_DIR="/cta/users/guneyn23/idr_results"


IDR_OUTPUT="${OUTPUT_DIR}/HelanoUV_R1_R3_IDR.txt"
IDR_LOG="${OUTPUT_DIR}/HelanoUV_R1_R3_IDR.log"


idr \
    --samples "$PEAK_R1" "$PEAK_R3" \
    --input-file-type narrowPeak \
    --rank p.value \
    --output-file "$IDR_OUTPUT" \
    --plot \
    --log-output-file "$IDR_LOG"

echo "Job finished."
date