#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=derived100kb
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_100kb/seaborn_mean_analysis/logs/derived_%j.out
#SBATCH --error=/cta/users/guneyn23/peak_center_100kb/seaborn_mean_analysis/logs/derived_%j.err
set -euo pipefail
BASE="/cta/users/guneyn23"
source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate plot_env
python "${BASE}/peak_center_100kb/seaborn_mean_analysis/seaborn_mean_analysis.py" derived
