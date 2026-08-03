na#!/usr/bin/env python3
from pathlib import Path
import pandas as pd

folder = Path("/cta/users/guneyn23/peak_center_20kb/rpkm/noUV_atac_damage_all")

cpd_real = "/cta/users/guneyn23/rpkm/CPD_rpkm/atac_rpkm/real_damage_rpkm.bed"
cpd_sim = "/cta/users/guneyn23/rpkm/CPD_rpkm/atac_rpkm/sim_damage_rpkm.bed"
damage64_real = "/cta/users/guneyn23/rpkm/64_rpkm/ATAC_real_64_rpkm.bed"
damage64_sim = "/cta/users/guneyn23/rpkm/64_rpkm/ATAC_simulated_64_rpkm.bed"


def read_first_four_columns(file):
    return pd.read_csv(file, sep="\t", 
    header=None, 
    usecols=[0, 1, 2, 3])


for file in folder.iterdir():
    
    if "CPD" in file.name and "_sim_" in file.name:
        reference = cpd_sim
    elif "CPD" in file.name:
        reference = cpd_real
    elif "_sim_" in file.name:
        reference = damage64_sim
    else:
        reference = damage64_real

    same = read_first_four_columns(file).equals(read_first_four_columns(reference))
    print(f"{file.name}: {'SAME' if same else 'DIFFERENT'}")
