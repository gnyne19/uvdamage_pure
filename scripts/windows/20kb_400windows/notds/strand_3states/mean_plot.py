#!/usr/bin/env python3
"""Calculate strand-specific mean RPKM and plot plus/minus profiles."""

import argparse
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

BASE = Path("/cta/users/guneyn23/peak_center_20kb/notDS_strand_3states")
RPKM_DIR = BASE / "rpkm"
PLOT_DIR = BASE / "plots"
SUMMARY = PLOT_DIR / "notDS_strand_3states_400windows_mean_rpkm.tsv"
PART_DIR = BASE / "mean_parts"
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("64", "CPD")
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
STRANDS = ("plus", "minus")
COLORS = {
    "1m": "#01befe", "15m": "#ffdd00", "30m": "#ff7d00",
    "1h": "#ff006d", "4h": "#adff02", "8h": "#8f00ff",
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

def summarize(path):
    counts = np.zeros(400, dtype=np.int64)
    sums = np.zeros(400, dtype=np.float64)
    with path.open() as handle:
        for line_number, line in enumerate(handle, 1):
            fields = line.rstrip().split("\t")
            if len(fields) < 6:
                raise ValueError(f"{path}:{line_number}: expected >=6 columns")
            window = int(fields[3].rsplit("_", 1)[1]) - 1
            counts[window] += 1
            sums[window] += float(fields[-1])
    if np.any(counts == 0) or not np.all(counts == counts[0]):
        raise ValueError(f"{path}: incomplete or unequal windows")
    windows = np.arange(1, 401)
    return pd.DataFrame({
        "window": windows,
        "distance_kb": -10 + (windows - 0.5) * 0.05,
        "n_peaks": counts,
        "mean_rpkm": sums / counts,
    })

def calculate():
    tables = []
    for region in REGIONS:
        for damage in DAMAGES:
            for time in TIMES:
                sample = SAMPLES[(damage, time)]
                for strand in STRANDS:
                    path = RPKM_DIR / (
                        f"{sample}_notDS_{strand}_{region}_400windows_rpkm.bed"
                    )
                    if not path.is_file():
                        raise FileNotFoundError(path)
                    table = summarize(path)
                    for column, value in reversed((
                        ("region", region), ("damage", damage),
                        ("time", time), ("strand", strand),
                    )):
                        table.insert(0, column, value)
                    tables.append(table)
    result = pd.concat(tables, ignore_index=True)
    PLOT_DIR.mkdir(parents=True, exist_ok=True)
    result.to_csv(SUMMARY, sep="\t", index=False)
    return result

def plot(summary):
    PLOT_DIR.mkdir(parents=True, exist_ok=True)
    for region in REGIONS:
        for damage in DAMAGES:
            selected = summary[
                (summary.region == region) & (summary.damage == damage)
            ]
            fig, ax = plt.subplots(figsize=(10, 5))
            for time in TIMES:
                for strand in STRANDS:
                    values = selected[
                        (selected.time == time) & (selected.strand == strand)
                    ].sort_values("window")
                    ax.plot(
                        values.distance_kb, values.mean_rpkm,
                        color=COLORS[time],
                        linestyle="-" if strand == "plus" else "--",
                        label=f"{time} ({'+' if strand == 'plus' else '-'})",
                    )
            ax.axvline(0, color="gray", linestyle=":", linewidth=1)
            ax.set_xlim(-10, 10)
            ax.set_ylim(0.18, 0.46)
            ax.set_xlabel(f"Distance from {region} center (kb)")
            ax.set_ylabel("Mean strand-specific notDS RPKM")
            ax.set_title(f"{region} {damage} — notDS by genomic strand")
            ax.legend(title="Time (strand)", ncol=2, fontsize=8)
            fig.tight_layout()
            output = PLOT_DIR / f"{region}_{damage}_notDS_strand_mean_rpkm.png"
            fig.savefig(output, dpi=300, bbox_inches="tight")
            plt.close(fig)

def combine_parts():
    paths = sorted(PART_DIR.glob("*_mean.tsv"))
    if len(paths) != 72:
        raise ValueError(f"Expected 72 mean parts, found {len(paths)} in {PART_DIR}")
    summary = pd.concat(
        (pd.read_csv(path, sep="\t", dtype={"damage": str}) for path in paths),
        ignore_index=True,
    )
    expected_rows = 72 * 400
    if len(summary) != expected_rows:
        raise ValueError(f"Expected {expected_rows} rows, found {len(summary)}")
    PLOT_DIR.mkdir(parents=True, exist_ok=True)
    summary.to_csv(SUMMARY, sep="\t", index=False)
    print(f"Saved: {SUMMARY}")
    return summary

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--plot-only", action="store_true")
    parser.add_argument("--from-parts", action="store_true")
    args = parser.parse_args()
    if args.plot_only and args.from_parts:
        parser.error("--plot-only and --from-parts cannot be used together")
    if args.from_parts:
        summary = combine_parts()
    elif args.plot_only:
        if not SUMMARY.is_file():
            raise FileNotFoundError(SUMMARY)
        summary = pd.read_csv(SUMMARY, sep="\t", dtype={"damage": str})
    else:
        summary = calculate()
    plot(summary)

if __name__ == "__main__":
    main()
