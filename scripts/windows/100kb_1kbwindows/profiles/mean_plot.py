#!/usr/bin/env python3
"""Create the standard real, simulated, and mean-real/mean-sim plots."""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


BASE = Path("/cta/users/guneyn23/peak_center_100kb/normal_3states")
RPKM_DIR = BASE / "rpkm"
OUT = BASE / "mean_no_ci_plots"
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("CPD", "64")
KINDS = ("real", "sim")
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
COLORS = {
    "1m": "#01befe",
    "15m": "#ffdd00",
    "30m": "#ff7d00",
    "1h": "#ff006d",
    "4h": "#adff02",
    "8h": "#8f00ff",
}


def means_by_window(path: Path) -> pd.DataFrame:
    n = np.zeros(100, dtype=np.int64)
    sums = np.zeros(100, dtype=np.float64)
    with path.open() as handle:
        for line_number, line in enumerate(handle, start=1):
            fields = line.rstrip().split("\t")
            if len(fields) < 6:
                raise ValueError(f"{path}:{line_number}: expected 6 columns")
            window = int(fields[3].rsplit("_", 1)[1]) - 1
            if not 0 <= window < 100:
                raise ValueError(f"{path}:{line_number}: invalid window")
            n[window] += 1
            sums[window] += float(fields[-1])
    if np.any(n == 0) or not np.all(n == n[0]):
        raise ValueError(f"{path}: incomplete or unequal windows")
    windows = np.arange(1, 101)
    return pd.DataFrame(
        {
            "window": windows,
            "mean_rpkm": sums / n,
            "distance_kb": -50 + (windows - 0.5),
            "n_peaks": n,
        }
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--regions",
        nargs="+",
        choices=REGIONS,
        default=list(REGIONS),
        help="Regions to process; default: all three regions",
    )
    args = parser.parse_args()
    selected_regions = tuple(args.regions)

    OUT.mkdir(parents=True, exist_ok=True)
    summaries = []
    for region in selected_regions:
        for damage in DAMAGES:
            for kind in KINDS:
                for time in TIMES:
                    path = (
                        RPKM_DIR
                        / f"{time}_{damage}_{kind}_{region}_100windows_rpkm.bed"
                    )
                    if not path.is_file():
                        raise FileNotFoundError(path)
                    table = means_by_window(path)
                    table.insert(0, "time", time)
                    table.insert(0, "kind", kind)
                    table.insert(0, "damage", damage)
                    table.insert(0, "region", region)
                    summaries.append(table)

    summary = pd.concat(summaries, ignore_index=True)
    summary_path = OUT / "100kb_mean_rpkm_no_ci_summary.tsv"
    summary.to_csv(summary_path, sep="\t", index=False)

    raw_y_min = 0.12
    raw_y_max = summary["mean_rpkm"].max() * 1.05
    for region in selected_regions:
        for damage in DAMAGES:
            for kind in KINDS:
                selected = summary[
                    (summary["region"] == region)
                    & (summary["damage"] == damage)
                    & (summary["kind"] == kind)
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
                ax.set_xlim(-50, 50)
                ax.set_ylim(raw_y_min, raw_y_max)
                ax.set_xlabel(f"Distance from {region} center (kb)")
                ax.set_ylabel("Mean RPKM")
                ax.set_title(f"{region} {damage} — {kind}")
                ax.legend(title="Time")
                fig.tight_layout()
                output = OUT / f"{region}_{damage}_{kind}_mean_rpkm_no_ci.png"
                fig.savefig(output, dpi=300, bbox_inches="tight")
                plt.close(fig)

    real_mean = summary[summary["kind"] == "real"][
        ["region", "damage", "time", "window", "distance_kb", "mean_rpkm"]
    ].rename(columns={"mean_rpkm": "real_mean_rpkm"})
    sim_mean = summary[summary["kind"] == "sim"][
        ["region", "damage", "time", "window", "mean_rpkm"]
    ].rename(columns={"mean_rpkm": "sim_mean_rpkm"})
    normalized = real_mean.merge(
        sim_mean,
        on=["region", "damage", "time", "window"],
        validate="one_to_one",
    )
    normalized["real_div_sim"] = normalized["real_mean_rpkm"] / normalized[
        "sim_mean_rpkm"
    ].replace(0, np.nan)
    ratio_path = OUT / "100kb_mean_rpkm_real_div_sim.tsv"
    normalized.to_csv(ratio_path, sep="\t", index=False)

    finite = normalized["real_div_sim"].replace([np.inf, -np.inf], np.nan).dropna()
    ratio_y_min = 0.6
    ratio_y_max = finite.max() * 1.05
    for region in selected_regions:
        for damage in DAMAGES:
            selected = normalized[
                (normalized["region"] == region)
                & (normalized["damage"] == damage)
            ]
            fig, ax = plt.subplots(figsize=(10, 5))
            for time in TIMES:
                values = selected[selected["time"] == time].sort_values("window")
                ax.plot(
                    values["distance_kb"],
                    values["real_div_sim"],
                    color=COLORS[time],
                    label=time,
                )
            ax.axhline(1, color="black", linestyle=":", linewidth=1)
            ax.axvline(0, color="gray", linestyle="--", linewidth=1)
            ax.set_xlim(-50, 50)
            ax.set_ylim(ratio_y_min, ratio_y_max)
            ax.set_xlabel(f"Distance from {region} center (kb)")
            ax.set_ylabel("Mean RPKM (Real / Sim)")
            ax.set_title(f"{region} {damage} — Real/Sim normalized")
            ax.legend(title="Time")
            fig.tight_layout()
            output = OUT / f"{region}_{damage}_mean_rpkm_real_div_sim.png"
            fig.savefig(output, dpi=300, bbox_inches="tight")
            plt.close(fig)

    plot_count = len(selected_regions) * len(DAMAGES) * 3
    print(f"Saved {plot_count} plots in: {OUT}")
    print(f"Saved: {summary_path}")
    print(f"Saved: {ratio_path}")


if __name__ == "__main__":
    main()
