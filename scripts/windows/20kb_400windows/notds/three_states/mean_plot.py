#!/usr/bin/env python3
"""Calculate or plot mean notDS RPKM across three chromatin states."""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


BASE = Path("/cta/users/guneyn23")
ATAC_DIR = BASE / "peak_center_20kb/notDS_noUV_ATAC/rpkm"
HETERO_DIR = BASE / "peak_center_20kb/notDS_3states/rpkm"
OUT = BASE / "peak_center_20kb/notDS_3states/plots"
SUMMARY_PATH = OUT / "notDS_3states_400windows_mean_rpkm.tsv"
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("64", "CPD")
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
COLORS = {
    "1m": "#01befe",
    "15m": "#ffdd00",
    "30m": "#ff7d00",
    "1h": "#ff006d",
    "4h": "#adff02",
    "8h": "#8f00ff",
}
SAMPLES = {
    ("64", "1m"): "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly",
    ("64", "15m"): "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly",
    ("64", "30m"): "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly",
    ("64", "1h"): "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly",
    ("64", "4h"): "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly",
    ("64", "8h"): "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly",
    ("CPD", "1m"): "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly",
    ("CPD", "15m"): "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly",
    ("CPD", "30m"): "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly",
    ("CPD", "1h"): "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly",
    ("CPD", "4h"): "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly",
    ("CPD", "8h"): "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly",
}


def rpkm_path(region: str, damage: str, time: str) -> Path:
    sample = SAMPLES[(damage, time)]
    if region == "ATAC":
        return ATAC_DIR / f"{sample}_notDS_noUV_ATAC_400windows_rpkm.bed"
    return HETERO_DIR / f"{sample}_notDS_{region}_400windows_rpkm.bed"


def means_by_window(path: Path) -> pd.DataFrame:
    n = np.zeros(400, dtype=np.int64)
    sums = np.zeros(400, dtype=np.float64)
    with path.open() as handle:
        for line_number, line in enumerate(handle, start=1):
            fields = line.rstrip().split("\t")
            if len(fields) < 6:
                raise ValueError(f"{path}:{line_number}: expected 6 columns")
            window = int(fields[3].rsplit("_", 1)[1]) - 1
            if not 0 <= window < 400:
                raise ValueError(f"{path}:{line_number}: invalid window")
            n[window] += 1
            sums[window] += float(fields[-1])
    if np.any(n == 0) or not np.all(n == n[0]):
        raise ValueError(f"{path}: incomplete or unequal windows")
    windows = np.arange(1, 401)
    return pd.DataFrame(
        {
            "window": windows,
            "distance_kb": -10 + (windows - 0.5) * 0.05,
            "n_peaks": n,
            "mean_rpkm": sums / n,
        }
    )


def calculate_summary() -> pd.DataFrame:
    summaries = []
    for region in REGIONS:
        for damage in DAMAGES:
            for time in TIMES:
                path = rpkm_path(region, damage, time)
                if not path.is_file():
                    raise FileNotFoundError(path)
                table = means_by_window(path)
                table.insert(0, "time", time)
                table.insert(0, "damage", damage)
                table.insert(0, "region", region)
                summaries.append(table)
    summary = pd.concat(summaries, ignore_index=True)
    OUT.mkdir(parents=True, exist_ok=True)
    summary.to_csv(SUMMARY_PATH, sep="\t", index=False)
    print(f"Saved: {SUMMARY_PATH}")
    return summary


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--plot-only",
        action="store_true",
        help="Use the existing mean TSV and only redraw the plots.",
    )
    args = parser.parse_args()

    if args.plot_only:
        if not SUMMARY_PATH.is_file():
            raise FileNotFoundError(SUMMARY_PATH)
        summary = pd.read_csv(SUMMARY_PATH, sep="\t")
        print(f"Using existing summary: {SUMMARY_PATH}")
    else:
        summary = calculate_summary()

    OUT.mkdir(parents=True, exist_ok=True)
    for region in REGIONS:
        for damage in DAMAGES:
            selected = summary[
                (summary["region"] == region) & (summary["damage"] == damage)
            ]
            fig, ax = plt.subplots(figsize=(10, 5))
            for time in TIMES:
                values = selected[selected["time"] == time].sort_values("window")
                ax.plot(
                    values["distance_kb"],
                    values["mean_rpkm"],
                    color=COLORS[time],
                    label=time,
                )
            ax.axvline(0, color="gray", linestyle="--", linewidth=1)
            ax.set_xlim(-10, 10)
            ax.set_ylim(0.18, 0.46)
            ax.set_xlabel(f"Distance from {region} center (kb)")
            ax.set_ylabel("Mean notDS RPKM")
            ax.set_title(f"{region} {damage} — notDS")
            ax.legend(title="Time")
            fig.tight_layout()
            output = OUT / f"{region}_{damage}_notDS_mean_rpkm.png"
            fig.savefig(output, dpi=300, bbox_inches="tight")
            plt.close(fig)
            print(f"Saved: {output}")


if __name__ == "__main__":
    main()
