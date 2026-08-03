#!/bin/bash
#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=mid_mdbf
#SBATCH --partition=mid_mdbf
#SBATCH --job-name=notDS_strand_mean
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --output=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/mean_%j.out
#SBATCH --error=/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states/logs/mean_%j.err

set -euo pipefail
BASE="/cta/users/guneyn23"
source "${BASE}/miniconda3/etc/profile.d/conda.sh"
conda activate plot_env
python "${BASE}/peak_center_20kb/notDS_strand_3states/mean_plot.py"

