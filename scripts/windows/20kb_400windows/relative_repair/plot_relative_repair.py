#!/usr/bin/env python3

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


base_dir = Path("/cta/users/guneyn23")
repair_dir = base_dir / "relative_repair"
sim_dir = base_dir / "peak_center_20kb/rpkm/noUV_atac_damage_all"
output_dir = repair_dir / "plots"

number_of_windows = 400
window_size_bp = 50
region_size_bp = number_of_windows * window_size_bp

time_points = ["15m", "30m", "1h", "4h", "8h"]
damage_types = ["CPD", "64"]

sim_files = {
    ("CPD", "15m"): "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "30m"): "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "1h"): "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "4h"): "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "8h"): "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("64", "15m"): "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("64", "30m"): "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("64", "1h"): "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("64", "4h"): "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
    ("64", "8h"): "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_DS_sim_noUV_ATAC_400windows_rpkm.bed",
}

sim_baseline_files = {
    "CPD": base_dir / "rpkm/CPD_rpkm/atac_rpkm/sim_damage_rpkm.bed",
    "64": base_dir / "rpkm/64_rpkm/ATAC_simulated_64_rpkm.bed",
}

colors = {
    "15m": "#ff595e",
    "30m": "#ffca3a",
    "1h": "#8ac926",
    "4h": "#1982c4",
    "8h": "#6a4c93",
}

output_dir.mkdir(parents=True, exist_ok=True)
summary_rows = []

for damage_type in damage_types:
    for time_point in time_points:
        repair_file = repair_dir / f"{damage_type}_{time_point}_relative_repair.tsv"
        sim_baseline_file = sim_baseline_files[damage_type]
        sim_later_file = sim_dir / sim_files[(damage_type, time_point)]

        repair_sum = [0.0] * number_of_windows
        sim_repair_sum = [0.0] * number_of_windows
        repair_count = [0] * number_of_windows
        sim_repair_count = [0] * number_of_windows
        negative_count = [0] * number_of_windows
        negative_sim_count = [0] * number_of_windows

        with open(repair_file) as repair_in, open(sim_baseline_file) as sim_1m_in, open(sim_later_file) as sim_later_in:
            next(repair_in)

            for repair_line, sim_1m_line, sim_later_line in zip(repair_in, sim_1m_in, sim_later_in, strict=True):
                repair_columns = repair_line.rstrip("\n").split("\t")
                sim_1m_columns = sim_1m_line.rstrip("\n").split("\t")
                sim_later_columns = sim_later_line.rstrip("\n").split("\t")

                window = int(repair_columns[3].rsplit("_", 1)[1]) - 1
                relative_repair = float(repair_columns[6])
                sim_1m_rpkm = float(sim_1m_columns[5])
                sim_later_rpkm = float(sim_later_columns[5])
                sim_relative_repair = sim_1m_rpkm - sim_later_rpkm

                if sim_relative_repair < 0:
                    negative_sim_count[window] += 1
                else:
                    sim_repair_sum[window] += sim_relative_repair
                    sim_repair_count[window] += 1

                if relative_repair < 0:
                    negative_count[window] += 1
                    continue

                repair_sum[window] += relative_repair
                repair_count[window] += 1

        for window in range(number_of_windows):
            mean_repair = None
            mean_sim_repair = None
            repair_div_sim_repair = None

            if repair_count[window] > 0:
                mean_repair = repair_sum[window] / repair_count[window]

            if sim_repair_count[window] > 0:
                mean_sim_repair = sim_repair_sum[window] / sim_repair_count[window]

            if mean_repair is not None and mean_sim_repair is not None and mean_sim_repair > 0:
                repair_div_sim_repair = mean_repair / mean_sim_repair

            distance_kb = ((window + 0.5) * window_size_bp - region_size_bp / 2) / 1000

            summary_rows.append(
                {
                    "damage_type": damage_type,
                    "time_point": time_point,
                    "window": window + 1,
                    "distance_kb": distance_kb,
                    "mean_relative_repair": mean_repair,
                    "mean_sim_relative_repair": mean_sim_repair,
                    "relative_repair_div_sim_repair": repair_div_sim_repair,
                    "n_repair_used": repair_count[window],
                    "n_sim_repair_used": sim_repair_count[window],
                    "n_skipped_negative": negative_count[window],
                    "n_skipped_negative_sim": negative_sim_count[window],
                }
            )

summary = pd.DataFrame(summary_rows)
summary_file = output_dir / "relative_repair_positive_mean_div_sim_repair.tsv"
summary.to_csv(summary_file, sep="\t", index=False)

for damage_type in damage_types:
    plt.figure(figsize=(10, 5))

    for time_point in time_points:
        data = summary[
            (summary["damage_type"] == damage_type)
            & (summary["time_point"] == time_point)
        ]
        plt.plot(
            data["distance_kb"],
            data["relative_repair_div_sim_repair"],
            color=colors[time_point],
            label=time_point,
        )

    plt.axvline(x=0, color="gray", linestyle="--", linewidth=1)
    plt.xlabel("Distance from ATAC peak center (kb)")
    plt.ylabel("Mean real relative repair / mean simulated relative repair")
    plt.title(f"{damage_type} relative repair normalized by simulated repair")
    plt.xlim(-10, 10)
    plt.xticks([-10, -5, 0, 5, 10])
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(title="Time", loc="upper right")
    plt.tight_layout()

    plot_file = output_dir / f"{damage_type}_relative_repair_div_sim_repair.png"
    plt.savefig(plot_file, dpi=300)
    plt.close()

print(summary_file)
