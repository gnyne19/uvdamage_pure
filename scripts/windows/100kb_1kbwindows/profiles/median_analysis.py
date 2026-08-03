#!/usr/bin/env python3
"""Summarize and plot 1-kb-window median RPKM profiles."""

import argparse
import math
from pathlib import Path

import numpy as np
import pandas as pd


BASE = Path("/cta/users/guneyn23/peak_center_100kb")
RPKM_DIR = BASE / "normal_3states/rpkm"
OUT = BASE / "median_analysis"
PART_DIR = OUT / "parts"
PLOT_DIR = OUT / "plots"
SUMMARY = OUT / "median_1kb_summary.tsv"
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("64", "CPD")
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
KINDS = ("real", "sim")
COLORS = {
    "1m": "#01befe",
    "15m": "#ffdd00",
    "30m": "#ff7d00",
    "1h": "#ff006d",
    "4h": "#adff02",
    "8h": "#8f00ff",
}


def summarize_file(path: Path, output: Path, region: str, damage: str,
                   time: str, kind: str) -> None:
    values = pd.read_csv(
        path,
        sep="\t",
        header=None,
        usecols=[5],
        dtype={5: np.float32},
    ).iloc[:, 0].to_numpy()
    if len(values) == 0 or len(values) % 100:
        raise ValueError(f"{path}: row count {len(values)} is not divisible by 100")

    matrix = values.reshape(-1, 100)
    n_peaks = matrix.shape[0]
    ordered = np.sort(matrix, axis=0)

    # Distribution-free, order-statistic 95% CI for the population median.
    # For large n, median rank SD is sqrt(n)/2.
    center = (n_peaks - 1) / 2
    offset = 1.96 * math.sqrt(n_peaks) / 2
    low_index = max(0, math.floor(center - offset))
    high_index = min(n_peaks - 1, math.ceil(center + offset))

    windows = np.arange(1, 101)
    result = pd.DataFrame(
        {
            "region": region,
            "damage": damage,
            "time": time,
            "kind": kind,
            "window": windows,
            "distance_kb": -50 + (windows - 0.5),
            "n_peaks": n_peaks,
            "median_rpkm": np.median(matrix, axis=0),
            "ci95_low": ordered[low_index, :],
            "ci95_high": ordered[high_index, :],
        }
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    result.to_csv(output, sep="\t", index=False)
    print(f"Saved: {output}")


def load_parts() -> pd.DataFrame:
    paths = sorted(PART_DIR.glob("*_median.tsv"))
    if len(paths) != 72:
        raise ValueError(f"Expected 72 median parts, found {len(paths)}")
    summary = pd.concat(
        (pd.read_csv(path, sep="\t", dtype={"damage": str}) for path in paths),
        ignore_index=True,
    )
    if len(summary) != 7200:
        raise ValueError(f"Expected 7200 summary rows, found {len(summary)}")
    summary.to_csv(SUMMARY, sep="\t", index=False)
    print(f"Saved: {SUMMARY}")
    return summary


def plot_profile(selected: pd.DataFrame, value: str, ylabel: str, title: str,
                 output: Path, show_ci: bool, ylim: tuple[float, float]) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(10, 5))
    for time in TIMES:
        values = selected[selected["time"] == time].sort_values("window")
        x = values["distance_kb"].to_numpy(dtype=float)
        y = values[value].to_numpy(dtype=float)
        ax.plot(x, y, color=COLORS[time], label=time, linewidth=1.5)
        if show_ci:
            low = values["ci95_low"].to_numpy(dtype=float)
            high = values["ci95_high"].to_numpy(dtype=float)
            ax.fill_between(x, low, high, color=COLORS[time], alpha=0.15)
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
    print(f"Saved: {output}")


def padded_limits(low: float, high: float) -> tuple[float, float]:
    span = high - low
    padding = span * 0.05 if span > 0 else max(abs(low) * 0.05, 0.01)
    return low - padding, high + padding


def make_plots(summary: pd.DataFrame) -> None:
    PLOT_DIR.mkdir(parents=True, exist_ok=True)

    rpkm_ylim = padded_limits(
        float(summary["ci95_low"].min()),
        float(summary["ci95_high"].max()),
    )

    keys = ["region", "damage", "time", "window", "distance_kb"]
    real_all = summary[summary["kind"] == "real"].rename(
        columns={"median_rpkm": "median_real"}
    )
    sim_all = summary[summary["kind"] == "sim"].rename(
        columns={"median_rpkm": "median_sim"}
    )
    ratio_all = real_all[keys + ["median_real"]].merge(
        sim_all[keys + ["median_sim"]], on=keys, validate="one_to_one"
    )
    if (ratio_all["median_sim"] <= 0).any():
        raise ValueError("Zero/non-positive sim median")
    ratio_all["real_over_sim"] = (
        ratio_all["median_real"] / ratio_all["median_sim"]
    )
    ratio_ylim = padded_limits(
        float(ratio_all["real_over_sim"].min()),
        float(ratio_all["real_over_sim"].max()),
    )

    baseline = ratio_all[ratio_all["time"] == "1m"][
        ["region", "damage", "window", "real_over_sim"]
    ].rename(columns={"real_over_sim": "ratio_1m"})
    repair_all = ratio_all.merge(
        baseline,
        on=["region", "damage", "window"],
        validate="many_to_one",
    )
    repair_all["relative_repair_percent"] = 100 * (
        1 - repair_all["real_over_sim"] / repair_all["ratio_1m"]
    )
    repair_ylim = padded_limits(
        float(repair_all["relative_repair_percent"].min()),
        float(repair_all["relative_repair_percent"].max()),
    )

    for region in REGIONS:
        for damage in DAMAGES:
            base = summary[
                (summary["region"] == region) & (summary["damage"] == damage)
            ].copy()

            for kind in KINDS:
                selected = base[base["kind"] == kind]
                plot_profile(
                    selected,
                    "median_rpkm",
                    f"Median {kind} RPKM",
                    f"{region} {damage} — median {kind} RPKM with 95% CI",
                    PLOT_DIR / f"{region}_{damage}_median_{kind}_rpkm_ci95.png",
                    True,
                    rpkm_ylim,
                )

            ratio = ratio_all[
                (ratio_all["region"] == region)
                & (ratio_all["damage"] == damage)
            ]
            plot_profile(
                ratio,
                "real_over_sim",
                "Median real / median sim",
                f"{region} {damage} — median real/sim",
                PLOT_DIR / f"{region}_{damage}_median_real_over_sim.png",
                False,
                ratio_ylim,
            )

            repair = repair_all[
                (repair_all["region"] == region)
                & (repair_all["damage"] == damage)
            ]
            plot_profile(
                repair,
                "relative_repair_percent",
                "Relative repair vs 1m (%)",
                f"{region} {damage} — relative repair vs 1m",
                PLOT_DIR / f"{region}_{damage}_relative_repair_vs_1m.png",
                False,
                repair_ylim,
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    summarize = subparsers.add_parser("summarize")
    summarize.add_argument("--input", type=Path, required=True)
    summarize.add_argument("--output", type=Path, required=True)
    summarize.add_argument("--region", choices=REGIONS, required=True)
    summarize.add_argument("--damage", choices=DAMAGES, required=True)
    summarize.add_argument("--time", choices=TIMES, required=True)
    summarize.add_argument("--kind", choices=KINDS, required=True)
    subparsers.add_parser("plot")
    args = parser.parse_args()

    if args.command == "summarize":
        summarize_file(
            args.input, args.output, args.region, args.damage, args.time, args.kind
        )
    else:
        make_plots(load_parts())


if __name__ == "__main__":
    main()
