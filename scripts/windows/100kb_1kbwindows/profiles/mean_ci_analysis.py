#!/usr/bin/env python3
"""Calculate mean/CI summaries from existing 1-kb RPKM files and plot them."""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

BASE = Path("/cta/users/guneyn23/peak_center_100kb")
OUT = BASE / "mean_ci_analysis"
PART_DIR = OUT / "parts"
PLOT_DIR = OUT / "plots"
SUMMARY = OUT / "mean_1kb_ci95_summary.tsv"
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("64", "CPD")
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
KINDS = ("real", "sim")
COLORS = {
    "1m": "#01befe", "15m": "#ffdd00", "30m": "#ff7d00",
    "1h": "#ff006d", "4h": "#adff02", "8h": "#8f00ff",
}


def summarize(path, output, region, damage, time, kind):
    values = pd.read_csv(
        path, sep="\t", header=None, usecols=[5], dtype={5: np.float32}
    ).iloc[:, 0].to_numpy()
    if len(values) == 0 or len(values) % 100:
        raise ValueError(f"{path}: invalid row count {len(values)}")
    matrix = values.reshape(-1, 100)
    n = matrix.shape[0]
    mean = matrix.mean(axis=0, dtype=np.float64)
    sd = matrix.std(axis=0, ddof=1, dtype=np.float64)
    margin = 1.96 * sd / np.sqrt(n)
    windows = np.arange(1, 101)
    result = pd.DataFrame({
        "region": region, "damage": damage, "time": time, "kind": kind,
        "window": windows, "distance_kb": -50 + (windows - 0.5),
        "n_peaks": n, "mean_rpkm": mean,
        "ci95_low": mean - margin, "ci95_high": mean + margin,
    })
    output.parent.mkdir(parents=True, exist_ok=True)
    result.to_csv(output, sep="\t", index=False)


def limits(low, high):
    span = high - low
    pad = span * 0.05 if span > 0 else max(abs(low) * 0.05, 0.01)
    return low - pad, high + pad


def draw(data, column, ylabel, title, output, ylim, ci=False):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(10, 5))
    for time in TIMES:
        values = data[data["time"] == time].sort_values("window")
        x = values["distance_kb"].to_numpy(float)
        y = values[column].to_numpy(float)
        ax.plot(x, y, color=COLORS[time], label=time)
        if ci:
            ax.fill_between(
                x,
                values["ci95_low"].to_numpy(float),
                values["ci95_high"].to_numpy(float),
                color=COLORS[time], alpha=0.15,
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


def plot_all():
    paths = sorted(PART_DIR.glob("*_mean_ci.tsv"))
    if len(paths) != 72:
        raise ValueError(f"Expected 72 parts, found {len(paths)}")
    summary = pd.concat(
        (pd.read_csv(p, sep="\t", dtype={"damage": str}) for p in paths),
        ignore_index=True,
    )
    summary.to_csv(SUMMARY, sep="\t", index=False)
    PLOT_DIR.mkdir(parents=True, exist_ok=True)

    rpkm_ylim = limits(summary["ci95_low"].min(), summary["ci95_high"].max())
    keys = ["region", "damage", "time", "window", "distance_kb"]
    real = summary[summary.kind == "real"][keys + ["mean_rpkm"]].rename(
        columns={"mean_rpkm": "mean_real"}
    )
    sim = summary[summary.kind == "sim"][keys + ["mean_rpkm"]].rename(
        columns={"mean_rpkm": "mean_sim"}
    )
    ratio = real.merge(sim, on=keys, validate="one_to_one")
    ratio["real_over_sim"] = ratio["mean_real"] / ratio["mean_sim"]
    ratio_ylim = limits(ratio.real_over_sim.min(), ratio.real_over_sim.max())
    baseline = ratio[ratio.time == "1m"][
        ["region", "damage", "window", "real_over_sim"]
    ].rename(columns={"real_over_sim": "ratio_1m"})
    repair = ratio.merge(
        baseline, on=["region", "damage", "window"], validate="many_to_one"
    )
    repair["relative_repair_percent"] = 100 * (
        1 - repair["real_over_sim"] / repair["ratio_1m"]
    )
    repair_ylim = limits(
        repair.relative_repair_percent.min(), repair.relative_repair_percent.max()
    )

    for region in REGIONS:
        for damage in DAMAGES:
            base = summary[
                (summary.region == region) & (summary.damage == damage)
            ]
            for kind in KINDS:
                draw(
                    base[base.kind == kind], "mean_rpkm", f"Mean {kind} RPKM",
                    f"{region} {damage} — mean {kind} RPKM with 95% CI",
                    PLOT_DIR / f"{region}_{damage}_mean_{kind}_rpkm_ci95.png",
                    rpkm_ylim, True,
                )
            r = ratio[(ratio.region == region) & (ratio.damage == damage)]
            draw(
                r, "real_over_sim", "Mean real / mean sim",
                f"{region} {damage} — mean real/sim",
                PLOT_DIR / f"{region}_{damage}_mean_real_over_sim.png",
                ratio_ylim,
            )
            q = repair[(repair.region == region) & (repair.damage == damage)]
            draw(
                q, "relative_repair_percent", "Relative repair vs 1m (%)",
                f"{region} {damage} — relative repair vs 1m",
                PLOT_DIR / f"{region}_{damage}_relative_repair_vs_1m.png",
                repair_ylim,
            )


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    s = sub.add_parser("summarize")
    s.add_argument("--input", type=Path, required=True)
    s.add_argument("--output", type=Path, required=True)
    s.add_argument("--region", choices=REGIONS, required=True)
    s.add_argument("--damage", choices=DAMAGES, required=True)
    s.add_argument("--time", choices=TIMES, required=True)
    s.add_argument("--kind", choices=KINDS, required=True)
    sub.add_parser("plot")
    args = parser.parse_args()
    if args.command == "summarize":
        summarize(
            args.input, args.output, args.region, args.damage, args.time, args.kind
        )
    else:
        plot_all()


if __name__ == "__main__":
    main()
