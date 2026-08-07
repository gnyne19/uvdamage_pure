#!/usr/bin/env python3
"""Plot filtered time points from an existing positive-relative summary."""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


BASE = Path("/cta/users/guneyn23/positive_relative")
REGIONS = ("ATAC", "H3K9me3", "H3K27me3")
DAMAGES = ("CPD", "64")
FILTERED_TIMES = {
    "CPD": ("15m", "1h", "4h", "8h"),
    "64": ("15m", "30m", "1h"),
}
COLORS = {
    20: {
        "15m": "#0072B2",
        "30m": "#E69F00",
        "1h": "#009E73",
        "4h": "#D55E00",
        "8h": "#CC79A7",
    },
    100: {
        "15m": "#ffdd00",
        "30m": "#ff7d00",
        "1h": "#ff006d",
        "4h": "#adff02",
        "8h": "#8f00ff",
    },
}
PLOT_TYPES = (
    (
        "real_mean_relative",
        "real_ci95_low",
        "real_ci95_high",
        "Mean positive real relative repair",
        "positive_real_relative",
    ),
    (
        "sim_mean_relative",
        "sim_ci95_low",
        "sim_ci95_high",
        "Mean positive simulated relative repair",
        "positive_sim_relative",
    ),
    (
        "real_over_sim",
        None,
        None,
        "Mean positive real / simulated relative repair",
        "positive_real_over_sim",
    ),
)


def plot_filtered_profiles(resolution):
    resolution_dir = BASE / f"{resolution}kb"
    summary_file = (
        resolution_dir
        / f"{resolution}kb_positive_relative_mean_ci95_summary.tsv"
    )
    if not summary_file.is_file():
        raise FileNotFoundError(summary_file)

    summary = pd.read_csv(summary_file, sep="\t", dtype={"damage": str})
    plot_dir = resolution_dir / "plots" / "final_filtered_timepoints"
    plot_dir.mkdir(parents=True, exist_ok=True)

    saved = []
    for region in REGIONS:
        for damage in DAMAGES:
            selected = summary[
                (summary["region"] == region)
                & (summary["damage"] == damage)
            ]
            for value, ci_low, ci_high, ylabel, suffix in PLOT_TYPES:
                fig, ax = plt.subplots(figsize=(10, 5))
                for time in FILTERED_TIMES[damage]:
                    data = selected[selected["time"] == time].sort_values("window")
                    if data.empty:
                        raise ValueError(
                            f"Missing summary rows: {resolution}kb "
                            f"{region} {damage} {time}"
                        )
                    ax.plot(
                        data["distance_kb"],
                        data[value],
                        color=COLORS[resolution][time],
                        label=time,
                    )
                    if ci_low is not None:
                        ax.fill_between(
                            data["distance_kb"],
                            data[ci_low],
                            data[ci_high],
                            color=COLORS[resolution][time],
                            alpha=0.15,
                        )

                ax.axvline(0, color="gray", linestyle="--", linewidth=1)
                ax.set_xlim(-resolution / 2, resolution / 2)
                ax.set_xlabel(f"Distance from {region} center (kb)")
                ax.set_ylabel(ylabel)
                ax.set_title(
                    f"{region} {damage} - positive relative repair "
                    f"({resolution} kb)"
                )
                ax.legend(title="Time", ncol=2)
                ax.grid(alpha=0.2)
                fig.tight_layout()
                output = (
                    plot_dir
                    / f"{region}_{damage}_{resolution}kb_final_filtered_{suffix}.png"
                )
                fig.savefig(output, dpi=300, bbox_inches="tight")
                plt.close(fig)
                saved.append(output)

    print(f"Saved {len(saved)} filtered plots in: {plot_dir}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--resolution", type=int, choices=(20, 100), required=True)
    args = parser.parse_args()
    plot_filtered_profiles(args.resolution)


if __name__ == "__main__":
    main()
