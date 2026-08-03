"""Create all 6-4PP and CPD RPKM line plots with a shared style.

For each damage type this script creates raw real/sim ratio, real RPKM,
simulated RPKM, and 6-10 kb baseline-normalized ratio plots.
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


BASE_DIR = Path(__file__).resolve().parent
COLORS = {
    "ATAC": "#d62828",
    "H3K9me3": "#003049",
    "H3K27me3": "#f77f00",
}
REGIONS = tuple(COLORS)
BASELINE_MIN_KB = 6
WINDOW_SIZE_KB = 0.05

DATASETS = {
    "64": {
        "display_name": "6-4PP",
        "files": {
            "ATAC": BASE_DIR / "64_rpkm/ATAC_mean_normalized_rpkm.tsv",
            "H3K9me3": BASE_DIR / "64_rpkm/H3K9me3_mean_normalized_rpkm.tsv",
            "H3K27me3": BASE_DIR / "64_rpkm/H3K27me3_mean_normalized_rpkm.tsv",
        },
        "output_dir": BASE_DIR / "64_rpkm",
    },
    "CPD": {
        "display_name": "CPD",
        "files": {
            "ATAC": BASE_DIR / "CPD_rpkm/atac_rpkm/mean_rpkm_ratio.tsv",
            "H3K9me3": BASE_DIR / "CPD_rpkm/close_rpkm/H3K9me3_mean_rpkm_ratio.tsv",
            "H3K27me3": BASE_DIR / "CPD_rpkm/close_rpkm/H3K27me3_mean_rpkm_ratio.tsv",
        },
        "output_dir": BASE_DIR / "CPD_rpkm",
    },
}

PLOTS = {
    "ratio": ("real_sim_ratio", "Mean real RPKM / mean simulated RPKM"),
    "real": ("mean_real_rpkm", "Mean real RPKM"),
    "simulated": ("mean_sim_rpkm", "Mean simulated RPKM"),
}


def load_dataset(files):
    tables = {region: pd.read_csv(path, sep="\t") for region, path in files.items()}
    lengths = {region: len(table) for region, table in tables.items()}
    if len(set(lengths.values())) != 1:
        raise ValueError(f"Window counts differ: {lengths}")
    return tables


def distance_axis(number_of_windows):
    """Return centers of 50-bp windows spanning -10 to +10 kb."""
    expected = int(20 / WINDOW_SIZE_KB)
    if number_of_windows != expected:
        raise ValueError(f"Expected {expected} windows, found {number_of_windows}")
    return (np.arange(number_of_windows) + 0.5) * WINDOW_SIZE_KB - 10


def style_axes(ax, horizontal_reference=None):
    if horizontal_reference is not None:
        ax.axhline(horizontal_reference, color="black", linestyle="--", linewidth=1)
    ax.axvline(0, color="#666666", linestyle="--", linewidth=1)
    ax.set_xlim(-10, 10)
    ax.set_xticks([-10, -5, 0, 5, 10])
    ax.set_xlabel("Distance from peak center (kb)")
    ax.grid(True, which="major", color="#c7c7c7", linestyle="--", linewidth=0.7, alpha=0.75)
    ax.set_axisbelow(True)
    ax.legend(frameon=False)


def plot_column(tables, column, ylabel, title, output_file, horizontal_reference=None):
    x = distance_axis(len(next(iter(tables.values()))))
    fig, ax = plt.subplots(figsize=(10, 5))
    for region in REGIONS:
        ax.plot(x, tables[region][column], color=COLORS[region], linewidth=1.8, label=region)
    style_axes(ax, horizontal_reference)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    fig.tight_layout()
    fig.savefig(output_file, dpi=300, bbox_inches="tight")
    plt.close(fig)


def baseline_normalize(tables):
    x = distance_axis(len(next(iter(tables.values()))))
    baseline_mask = (x <= -BASELINE_MIN_KB) | (x >= BASELINE_MIN_KB)
    normalized = {}
    baselines = {}
    rows = []
    for region in REGIONS:
        values = tables[region]["real_sim_ratio"].to_numpy(dtype=float)
        baseline = float(np.nanmean(values[baseline_mask]))
        if not np.isfinite(baseline) or baseline == 0:
            raise ValueError(f"{region}: invalid 6-10 kb baseline: {baseline}")
        baselines[region] = baseline
        normalized[region] = pd.DataFrame({"baseline_normalized_ratio": values / baseline})
        rows.append(pd.DataFrame({
            "distance_kb": x,
            "real_sim_ratio": values,
            "baseline_normalized_ratio": values / baseline,
            "region": region,
        }))
    return normalized, baselines, pd.concat(rows, ignore_index=True)


def create_dataset_plots(dataset_key, config):
    tables = load_dataset(config["files"])
    output_dir = config["output_dir"]
    output_dir.mkdir(parents=True, exist_ok=True)
    name = config["display_name"]

    outputs = []
    for plot_name, (column, ylabel) in PLOTS.items():
        output = output_dir / f"{dataset_key}_{plot_name}_styled.png"
        reference = 1 if plot_name == "ratio" else None
        plot_column(tables, column, ylabel, f"{name} {plot_name.title()} Around Peak Centers", output, reference)
        outputs.append(output)

    normalized, baselines, baseline_table = baseline_normalize(tables)
    baseline_png = output_dir / f"{dataset_key}_baseline_6_10kb_styled.png"
    baseline_tsv = output_dir / f"{dataset_key}_baseline_6_10kb_styled.tsv"
    plot_column(
        normalized,
        "baseline_normalized_ratio",
        "6-10 kb baseline-normalized real/sim ratio",
        f"{name} Damage Enrichment (6-10 kb Baseline)",
        baseline_png,
        horizontal_reference=1,
    )
    baseline_table.to_csv(baseline_tsv, sep="\t", index=False)
    outputs.extend([baseline_png, baseline_tsv])
    return outputs, baselines


def main():
    for dataset_key, config in DATASETS.items():
        outputs, baselines = create_dataset_plots(dataset_key, config)
        print(f"{dataset_key} baselines: {baselines}")
        for output in outputs:
            print(f"Written: {output}")


if __name__ == "__main__":
    main()
