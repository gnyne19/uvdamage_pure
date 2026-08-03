#!/usr/bin/env python3
from pathlib import Path
import gc
import pandas as pd

columns = ["chrom", "start", "end", "peak", "count", "rpkm"]
peak_columns = ["chrom", "start", "end", "peak"]
base = Path("/cta/users/guneyn23/peak_center_20kb/rpkm/noUV_atac_damage_all")
output = Path("/cta/users/guneyn23/relative_repair")


def make_relative_file(reference_file, timepoint_file, output_name):
    reference = pd.read_csv(reference_file, sep="\t", header=None, names=columns)
    timepoint = pd.read_csv(timepoint_file, sep="\t", header=None, names=columns)


    result = timepoint.iloc[:, :5].copy()
    result["relative_rpkm"] = (reference["rpkm"] - timepoint["rpkm"])
    result.to_csv(
        output / output_name,
        sep="\t",
        index=False,
        header=False,
        float_format="%.2f",
    )
    print(f"Written: {output / output_name}", flush=True)
    del reference, timepoint, result
    gc.collect()


cpd_real = Path("/cta/users/guneyn23/rpkm/CPD_rpkm/atac_rpkm/real_damage_rpkm.bed")
make_relative_file(cpd_real, base / "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "CPD_15m_real_relative_rpkm.tsv")
make_relative_file(cpd_real, base / "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "CPD_30m_real_relative_rpkm.tsv")
make_relative_file(cpd_real, base / "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "CPD_1h_real_relative_rpkm.tsv")
make_relative_file(cpd_real, base / "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "CPD_4h_real_relative_rpkm.tsv")
make_relative_file(cpd_real, base / "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "CPD_8h_real_relative_rpkm.tsv")

cpd_sim = Path("/cta/users/guneyn23/rpkm/CPD_rpkm/atac_rpkm/sim_damage_rpkm.bed")
make_relative_file(cpd_sim, base / "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "CPD_15m_sim_relative_rpkm.tsv")
make_relative_file(cpd_sim, base / "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "CPD_30m_sim_relative_rpkm.tsv")
make_relative_file(cpd_sim, base / "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "CPD_1h_sim_relative_rpkm.tsv")
make_relative_file(cpd_sim, base / "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "CPD_4h_sim_relative_rpkm.tsv")
make_relative_file(cpd_sim, base / "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "CPD_8h_sim_relative_rpkm.tsv")

damage64_real = Path("/cta/users/guneyn23/rpkm/64_rpkm/ATAC_real_64_rpkm.bed")
make_relative_file(damage64_real, base / "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "64_15m_real_relative_rpkm.tsv")
make_relative_file(damage64_real, base / "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "64_30m_real_relative_rpkm.tsv")
make_relative_file(damage64_real, base / "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "64_1h_real_relative_rpkm.tsv")
make_relative_file(damage64_real, base / "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "64_4h_real_relative_rpkm.tsv")
make_relative_file(damage64_real, base / "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_noUV_ATAC_400windows_rpkm.bed", "64_8h_real_relative_rpkm.tsv")

damage64_sim = Path("/cta/users/guneyn23/rpkm/64_rpkm/ATAC_simulated_64_rpkm.bed")
make_relative_file(damage64_sim, base / "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "64_15m_sim_relative_rpkm.tsv")
make_relative_file(damage64_sim, base / "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "64_30m_sim_relative_rpkm.tsv")
make_relative_file(damage64_sim, base / "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "64_1h_sim_relative_rpkm.tsv")
make_relative_file(damage64_sim, base / "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "64_4h_sim_relative_rpkm.tsv")
make_relative_file(damage64_sim, base / "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed", "64_8h_sim_relative_rpkm.tsv")
