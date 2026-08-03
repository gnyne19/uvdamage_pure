#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=hetchrRYA_simoverlapCPD
#SBATCH --output=/cta/users/guneyn23/htrchr_sim_overlap/hetchrRYA_simoverlapCPD_%j.out
#SBATCH --error=/cta/users/guneyn23/htrchr_sim_overlap/hetchrRYA_simoverlapCPD%j.err
#SBATCH --mem=8G


echo "job started"
date
source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq


bedtools intersect \
    -a /cta/users/guneyn23/encode/ENCFF584RYA.bed \
    -b /cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_r44_DS_sim.bed\
    -wa \
    -F 0.51 \
    -c \
 >/cta/users/guneyn23/htrchr_sim_overlap/CPD_sim_overlapping_hetchrsRYA.bed

echo "job finished"
date

