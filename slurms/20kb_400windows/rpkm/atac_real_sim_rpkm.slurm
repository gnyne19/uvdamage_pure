#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=damage_rpkm
#SBATCH --output=/cta/users/guneyn23/rpkm/damage_rpkm_%j.out
#SBATCH --error=/cta/users/guneyn23/rpkm/damage_rpkm_%j.err
#SBATCH --mem=8G



echo "RPKM calculation started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate atacseq

python /cta/users/guneyn23/rpkm/real_sim_rpkm.py

echo "RPKM calculation completed"
date