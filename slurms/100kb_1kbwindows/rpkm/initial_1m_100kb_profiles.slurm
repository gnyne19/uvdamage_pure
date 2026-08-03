#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=initial_1m_100kb
#SBATCH --mem=4G
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/normal_3states/initial_1m_profiles/initial_1m_%j.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/normal_3states/initial_1m_profiles/initial_1m_%j.err

set -e

echo "Initial 1m 100 kb profiles started"
date

source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh
conda activate plot_env

python /cta/users/guneyn23/peak_center_100kb/normal_3states/initial_1m_profiles/initial_1m_profiles.py

echo "Initial 1m 100 kb profiles completed"
date
