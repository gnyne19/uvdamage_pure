#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=idr_filter
#SBATCH --output=/cta/users/guneyn23/idr_results/idr_filter_%j.out
#SBATCH --error=/cta/users/guneyn23/idr_results/idr_filter_%j.err
#SBATCH --mem=1G

IDR_TXT="/cta/users/guneyn23/idr_results/HelanoUV_R1_R3_IDR.txt"
FINAL_PEAKS="/cta/users/guneyn23/idr_results/HelanoUV_R1_R3_IDR_0.05.narrowPeak"

awk 'BEGIN{OFS="\t"} $12 >= 1.30103 {
    print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10
}' "$IDR_TXT" > "$FINAL_PEAKS"

echo "Peaks that pass idr filter:"
wc -l "$FINAL_PEAKS"
