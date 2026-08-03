#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=H3k27me3calculate_rpkm
#SBATCH --output=/cta/users/guneyn23/rpkm/close_rpkm/H3k27me3calculate_rpkm_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/close_rpkm/H3k27me3calculate_rpkm_%j.err
#SBATCH --mem=16G

echo "Job started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

python rpkm/close_rpkm/close_real_sim_rpkm.py \
    /cta/users/guneyn23/close_peak_center_20kb/overlaps/CPD_damage_overlapping_H3K27me3__peaks.bed \
    /cta/users/guneyn23/close_peak_center_20kb/overlaps/CPD_sim_overlapping_H3K27me3__peaks.bed \
    /cta/users/guneyn23/damageseq_data/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed \
    /cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed \
    /cta/users/guneyn23/rpkm/close_rpkm/H3k27me3_real_rpkm.bed \
    /cta/users/guneyn23/rpkm/close_rpkm/H3k27me3_sim_rpkm.bed 


echo "Job completed"
date