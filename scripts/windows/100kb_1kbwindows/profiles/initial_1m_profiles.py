#!/usr/bin/env python3
"""Plot initial 1m real, simulated, and real/sim mean RPKM profiles."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


BASE = Path("/cta/users/guneyn23/peak_center_100kb/normal_3states")
INPUT = BASE / "mean_no_ci_plots/100kb_mean_rpkm_no_ci_summary.tsv"
OUTPUT = BASE / "initial_1m_profiles/plots"
REGIONS = ["ATAC", "H3K9me3", "H3K27me3"]
DAMAGES = ["CPD", "64"]
COLORS = {
    "ATAC": "#d62828",
    "H3K9me3": "#003049",
    "H3K27me3": "#f77f00",
}


def draw(data, column, ylabel, title, output):
    fig, ax = plt.subplots(figsize=(10, 5))
    for region in REGIONS:
        selected = data[data["region"] == region].sort_values("window")
        ax.plot(
            selected["distance_kb"],
            selected[column],
            color=COLORS[region],
            linewidth=1.8,
            label=region,
        )
    ax.axvline(0, color="gray", linestyle="--", linewidth=1)
    ax.set_xlim(-50, 50)
    ax.set_xlabel("Distance from chromatin-state center (kb)")
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.legend(title="Chromatin state")
    ax.grid(alpha=0.2)
    fig.tight_layout()
    fig.savefig(output, dpi=300, bbox_inches="tight")
    plt.close(fig)


def main():
    summary = pd.read_csv(INPUT, sep="\t", dtype={"damage": str})
    summary = summary[summary["time"] == "1m"].copy()
    OUTPUT.mkdir(parents=True, exist_ok=True)

    for damage in DAMAGES:
        selected = summary[summary["damage"] == damage]
        real = selected[selected["kind"] == "real"].copy()
        sim = selected[selected["kind"] == "sim"].copy()

        draw(
            real,
            "mean_rpkm",
            "Mean real RPKM",
            f"{damage} - initial 1m real damage profiles",
            OUTPUT / f"{damage}_1m_real_mean_rpkm_3states.png",
        )
        draw(
            sim,
            "mean_rpkm",
            "Mean simulated RPKM",
            f"{damage} - initial 1m simulated damage profiles",
            OUTPUT / f"{damage}_1m_sim_mean_rpkm_3states.png",
        )

        ratio_tables = []
        for region in REGIONS:
            region_real = real[real["region"] == region]
            region_sim = sim[sim["region"] == region]
            ratio = region_real[["window", "distance_kb", "mean_rpkm"]].merge(
                region_sim[["window", "mean_rpkm"]],
                on="window",
                suffixes=("_real", "_sim"),
                validate="one_to_one",
            )
            ratio["region"] = region
            ratio["real_over_sim"] = (
                ratio["mean_rpkm_real"] / ratio["mean_rpkm_sim"]
            )
            ratio_tables.append(ratio)

        draw(
            pd.concat(ratio_tables, ignore_index=True),
            "real_over_sim",
            "Mean real / mean simulated RPKM",
            f"{damage} - initial 1m real/sim profiles",
            OUTPUT / f"{damage}_1m_real_over_sim_3states.png",
        )

    print(f"Saved plots: {OUTPUT}")


if __name__ == "__main__":
    main()
