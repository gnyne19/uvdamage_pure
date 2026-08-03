#!/usr/bin/env python3
"""Seaborn mean/CI plots plus derived ratio and relative-repair plots."""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

BASE = Path("/cta/users/guneyn23/peak_center_100kb")
RPKM_DIR = BASE / "normal_3states/rpkm"
MEAN_TSV = (
    BASE / "normal_3states/mean_no_ci_plots/100kb_mean_rpkm_no_ci_summary.tsv"
)
OUT = BASE / "seaborn_mean_analysis/plots"
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("64", "CPD")
KINDS = ("real", "sim")
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
COLORS = {
    "1m": "#01befe", "15m": "#ffdd00", "30m": "#ff7d00",
    "1h": "#ff006d", "4h": "#adff02", "8h": "#8f00ff",
}


def padded(low, high):
    span = high - low
    pad = span * 0.05 if span > 0 else max(abs(low) * 0.05, 0.01)
    return low - pad, high + pad


def rpkm_ylim():
    summary = pd.read_csv(MEAN_TSV, sep="\t", dtype={"damage": str})
    return padded(summary.mean_rpkm.min(), summary.mean_rpkm.max())


def seaborn_plot(region, damage, kind, n_boot):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import seaborn as sns

    OUT.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(10, 5))
    distances = np.arange(100, dtype=np.float32) - 49.5
    for time in TIMES:
        path = RPKM_DIR / f"{time}_{damage}_{kind}_{region}_100windows_rpkm.bed"
        values = pd.read_csv(
            path, sep="\t", header=None, usecols=[5], dtype={5: np.float32},
            names=["rpkm"],
        )
        if len(values) % 100:
            raise ValueError(f"{path}: invalid row count")
        values["distance_kb"] = np.tile(distances, len(values) // 100)
        sns.lineplot(
            data=values, x="distance_kb", y="rpkm",
            estimator="mean", errorbar=("ci", 95),
            n_boot=n_boot, seed=42, color=COLORS[time],
            label=time, linewidth=1.5, ax=ax,
        )
    ax.axvline(0, color="gray", linestyle="--", linewidth=1)
    ax.set_xlim(-50, 50)
    ax.set_ylim(*rpkm_ylim())
    ax.set_xlabel(f"Distance from {region} center (kb)")
    ax.set_ylabel(f"Mean {kind} RPKM")
    ax.set_title(f"{region} {damage} — mean {kind} RPKM with seaborn 95% CI")
    ax.legend(title="Time", ncol=2)
    ax.grid(alpha=0.2)
    fig.tight_layout()
    output = OUT / f"{region}_{damage}_mean_{kind}_seaborn_ci95.png"
    fig.savefig(output, dpi=300, bbox_inches="tight")
    plt.close(fig)


def draw_derived(data, column, ylabel, title, output, ylim):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(10, 5))
    for time in TIMES:
        values = data[data.time == time].sort_values("window")
        ax.plot(
            values.distance_kb, values[column],
            color=COLORS[time], label=time,
        )
    ax.axvline(0, color="gray", linestyle="--", linewidth=1)
    ax.set_xlim(-50, 50)
    ax.set_ylim(*ylim)
    ax.set_xlabel("Distance from peak center (kb)")
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.legend(title="Time", ncol=2)
    ax.grid(alpha=0.2)
    fig.tight_layout()
    fig.savefig(output, dpi=300, bbox_inches="tight")
    plt.close(fig)


def derived_plots():
    summary = pd.read_csv(MEAN_TSV, sep="\t", dtype={"damage": str})
    keys = ["region", "damage", "time", "window", "distance_kb"]
    real = summary[summary.kind == "real"][keys + ["mean_rpkm"]].rename(
        columns={"mean_rpkm": "mean_real"}
    )
    sim = summary[summary.kind == "sim"][keys + ["mean_rpkm"]].rename(
        columns={"mean_rpkm": "mean_sim"}
    )
    ratio = real.merge(sim, on=keys, validate="one_to_one")
    ratio["real_over_sim"] = ratio.mean_real / ratio.mean_sim
    ratio_lim = padded(ratio.real_over_sim.min(), ratio.real_over_sim.max())
    baseline = ratio[ratio.time == "1m"][
        ["region", "damage", "window", "real_over_sim"]
    ].rename(columns={"real_over_sim": "ratio_1m"})
    repair = ratio.merge(
        baseline, on=["region", "damage", "window"], validate="many_to_one"
    )
    repair["relative_repair_percent"] = 100 * (
        1 - repair.real_over_sim / repair.ratio_1m
    )
    repair_lim = padded(
        repair.relative_repair_percent.min(),
        repair.relative_repair_percent.max(),
    )
    OUT.mkdir(parents=True, exist_ok=True)
    for region in REGIONS:
        for damage in DAMAGES:
            r = ratio[(ratio.region == region) & (ratio.damage == damage)]
            draw_derived(
                r, "real_over_sim", "Mean real / mean sim",
                f"{region} {damage} — mean real/sim",
                OUT / f"{region}_{damage}_mean_real_over_sim.png", ratio_lim,
            )
            q = repair[(repair.region == region) & (repair.damage == damage)]
            draw_derived(
                q, "relative_repair_percent", "Relative repair vs 1m (%)",
                f"{region} {damage} — relative repair vs 1m",
                OUT / f"{region}_{damage}_relative_repair_vs_1m.png", repair_lim,
            )


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    plot = sub.add_parser("seaborn")
    plot.add_argument("--region", choices=REGIONS, required=True)
    plot.add_argument("--damage", choices=DAMAGES, required=True)
    plot.add_argument("--kind", choices=KINDS, required=True)
    plot.add_argument("--n-boot", type=int, default=100)
    sub.add_parser("derived")
    args = parser.parse_args()
    if args.command == "seaborn":
        seaborn_plot(args.region, args.damage, args.kind, args.n_boot)
    else:
        derived_plots()


if __name__ == "__main__":
    main()
