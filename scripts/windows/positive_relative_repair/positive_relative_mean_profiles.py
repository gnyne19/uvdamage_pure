#!/usr/bin/env python3
"""Calculate positive relative repair first, then take window means."""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


HOME = Path("/cta/users/guneyn23")
REGIONS = ["ATAC", "H3K9me3", "H3K27me3"]
DAMAGES = ["CPD", "64"]
TIMES = ["15m", "30m", "1h", "4h", "8h"]
COLORS_20KB = {
    "15m": "#0072B2",
    "30m": "#E69F00",
    "1h": "#009E73",
    "4h": "#D55E00",
    "8h": "#CC79A7",
}
COLORS_100KB = {
    "15m": "#ffdd00",
    "30m": "#ff7d00",
    "1h": "#ff006d",
    "4h": "#adff02",
    "8h": "#8f00ff",
}


def baseline_20kb(region, damage, kind):
    if damage == "64":
        label = "simulated" if kind == "sim" else "real"
        return HOME / "rpkm_1m/64_rpkm" / f"{region}_{label}_64_rpkm.bed"

    label = "sim" if kind == "sim" else "real"
    if region == "ATAC":
        return HOME / "rpkm_1m/CPD_rpkm/atac_rpkm" / f"{label}_damage_rpkm.bed"

    region_label = {"H3K9me3": "H3k9me3", "H3K27me3": "H3k27me3"}[region]
    return (
        HOME
        / "rpkm_1m/CPD_rpkm/close_rpkm"
        / f"{region_label}_{label}_rpkm.bed"
    )


def timepoint_20kb(region, damage, time, kind):
    if region == "ATAC":
        folder = HOME / "peak_center_20kb/ATAC_rpkm/noUV_atac_damage_all"
        suffix = "noUV_ATAC_400windows_rpkm.bed"
    else:
        folder = HOME / "peak_center_20kb/close_rpkm" / region
        suffix = f"{region}_400windows_rpkm.bed"

    sim_marker = "_sim_" if kind == "sim" else "_"
    files = list(folder.glob(f"R3Hela_{time}{damage}_*DS{sim_marker}{suffix}"))
    if len(files) != 1:
        raise FileNotFoundError(
            f"Expected one {region} {damage} {time} {kind} file, found {files}"
        )
    return files[0]


def input_files(resolution, region, damage, time, kind):
    if resolution == 20:
        return (
            baseline_20kb(region, damage, kind),
            timepoint_20kb(region, damage, time, kind),
        )

    folder = HOME / "peak_center_100kb/normal_3states/rpkm"
    baseline = folder / f"1m_{damage}_{kind}_{region}_100windows_rpkm.bed"
    timepoint = folder / f"{time}_{damage}_{kind}_{region}_100windows_rpkm.bed"
    return baseline, timepoint


def read_rpkm(path):
    return pd.read_csv(
        path, sep="\t", header=None, usecols=[5], dtype={5: np.float64}
    ).iloc[:, 0]


def positive_relative_mean(baseline_rpkm, timepoint_file, number_of_windows):
    timepoint_rpkm = read_rpkm(timepoint_file)
    if len(baseline_rpkm) != len(timepoint_rpkm):
        raise ValueError(
            f"Row count differs: baseline={len(baseline_rpkm)}, "
            f"timepoint={len(timepoint_rpkm)} ({timepoint_file})"
        )
    if len(baseline_rpkm) % number_of_windows:
        raise ValueError(f"Invalid row count in {timepoint_file}")

    data = pd.DataFrame(
        {
            "window": np.tile(
                np.arange(1, number_of_windows + 1),
                len(baseline_rpkm) // number_of_windows,
            ),
            "relative": (
                baseline_rpkm.to_numpy() - timepoint_rpkm.to_numpy()
            )
            / baseline_rpkm.to_numpy(),
        }
    )

    all_counts = data.groupby("window").size().rename("n_observed")
    invalid_counts = (
        (~np.isfinite(data["relative"]))
        .groupby(data["window"])
        .sum()
        .rename("n_invalid_removed")
    )
    negative_counts = (
        (np.isfinite(data["relative"]) & (data["relative"] < 0))
        .groupby(data["window"])
        .sum()
        .rename("n_negative_removed")
    )

    positive = data[np.isfinite(data["relative"]) & (data["relative"] >= 0)]
    summary = positive.groupby("window")["relative"].agg(
        n_kept="count", mean_relative="mean", sd_relative="std"
    )
    summary["se"] = summary["sd_relative"] / np.sqrt(summary["n_kept"])
    summary["ci95_low"] = summary["mean_relative"] - 1.96 * summary["se"]
    summary["ci95_high"] = summary["mean_relative"] + 1.96 * summary["se"]

    return (
        summary.join(all_counts)
        .join(negative_counts)
        .join(invalid_counts)
        .reset_index()
    )


def task_combinations():
    return [
        (region, damage, time)
        for region in REGIONS
        for damage in DAMAGES
        for time in TIMES
    ]


def calculate(resolution, task_id=None):
    number_of_windows = 400 if resolution == 20 else 100
    window_size_kb = 0.05 if resolution == 20 else 1.0
    results = []
    selected_task = None
    if task_id is not None:
        selected_task = task_combinations()[task_id]

    for region in REGIONS:
        for damage in DAMAGES:
            baseline_cache = {}
            for time in TIMES:
                if selected_task is not None and (region, damage, time) != selected_task:
                    continue
                kind_tables = {}

                for kind in ["real", "sim"]:
                    baseline_file, timepoint_file = input_files(
                        resolution, region, damage, time, kind
                    )
                    print(f"{resolution}kb {region} {damage} {time} {kind}", flush=True)
                    if kind not in baseline_cache:
                        baseline_cache[kind] = read_rpkm(baseline_file)
                    table = positive_relative_mean(
                        baseline_cache[kind], timepoint_file, number_of_windows
                    )
                    table = table.rename(
                        columns={
                            column: f"{kind}_{column}"
                            for column in table.columns
                            if column != "window"
                        }
                    )
                    kind_tables[kind] = table

                result = kind_tables["real"].merge(
                    kind_tables["sim"], on="window", validate="one_to_one"
                )
                result["real_over_sim"] = (
                    result["real_mean_relative"] / result["sim_mean_relative"]
                )

                result.insert(
                    1,
                    "distance_kb",
                    (result["window"] - (number_of_windows + 1) / 2)
                    * window_size_kb,
                )
                result.insert(0, "time", time)
                result.insert(0, "damage", damage)
                result.insert(0, "region", region)
                result.insert(0, "resolution_kb", resolution)
                results.append(result)

    return pd.concat(results, ignore_index=True)


def combine_parts(resolution, output_dir):
    part_dir = output_dir / "parts"
    files = sorted(part_dir.glob("*.tsv"))
    if len(files) != 30:
        raise ValueError(f"Expected 30 part tables in {part_dir}, found {len(files)}")
    return pd.concat(
        (pd.read_csv(path, sep="\t", dtype={"damage": str}) for path in files),
        ignore_index=True,
    )


def plot_profiles(summary, resolution, output_dir):
    plot_dir = output_dir / "plots"
    plot_dir.mkdir(parents=True, exist_ok=True)
    colors = COLORS_20KB if resolution == 20 else COLORS_100KB

    plot_types = [
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
    ]

    for region in REGIONS:
        for damage in DAMAGES:
            selected = summary[
                (summary["region"] == region) & (summary["damage"] == damage)
            ]

            for value, ci_low, ci_high, ylabel, suffix in plot_types:
                fig, ax = plt.subplots(figsize=(10, 5))

                for time in TIMES:
                    data = selected[selected["time"] == time].sort_values("window")
                    ax.plot(
                        data["distance_kb"],
                        data[value],
                        color=colors[time],
                        label=time,
                    )
                    if ci_low is not None:
                        ax.fill_between(
                            data["distance_kb"],
                            data[ci_low],
                            data[ci_high],
                            color=colors[time],
                            alpha=0.15,
                        )

                ax.axvline(0, color="gray", linestyle="--", linewidth=1)
                ax.set_xlim(-resolution / 2, resolution / 2)
                ax.set_xlabel(f"Distance from {region} center (kb)")
                ax.set_ylabel(ylabel)
                ax.set_title(
                    f"{region} {damage} - positive relative repair ({resolution} kb)"
                )
                ax.legend(title="Time", ncol=2)
                ax.grid(alpha=0.2)
                fig.tight_layout()
                fig.savefig(
                    plot_dir / f"{region}_{damage}_{resolution}kb_{suffix}.png",
                    dpi=300,
                    bbox_inches="tight",
                )
                plt.close(fig)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--resolution", type=int, choices=[20, 100], required=True)
    parser.add_argument("--task-id", type=int, choices=range(30))
    parser.add_argument("--combine", action="store_true")
    args = parser.parse_args()
    if args.task_id is not None and args.combine:
        parser.error("--task-id and --combine cannot be used together")

    output_dir = HOME / "positive_relative" / f"{args.resolution}kb"
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.combine:
        summary = combine_parts(args.resolution, output_dir)
    elif args.task_id is not None:
        summary = calculate(args.resolution, args.task_id)
        region, damage, time = task_combinations()[args.task_id]
        part_dir = output_dir / "parts"
        part_dir.mkdir(parents=True, exist_ok=True)
        part_file = part_dir / f"{region}_{damage}_{time}.tsv"
        summary.to_csv(part_file, sep="\t", index=False)
        print(f"Saved: {part_file}", flush=True)
        return
    else:
        summary = calculate(args.resolution)

    summary_file = (
        output_dir
        / f"{args.resolution}kb_positive_relative_mean_ci95_summary.tsv"
    )
    summary.to_csv(summary_file, sep="\t", index=False)
    plot_profiles(summary, args.resolution, output_dir)

    print(f"Saved: {summary_file}", flush=True)
    print(f"Saved plots: {output_dir / 'plots'}", flush=True)


if __name__ == "__main__":
    main()
