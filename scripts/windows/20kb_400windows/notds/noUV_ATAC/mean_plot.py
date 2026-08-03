#!/usr/bin/env python3
"""Calculate mean notDS RPKM per noUV ATAC window and plot time courses."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


BASE = Path("/cta/users/guneyn23/peak_center_20kb/notDS_noUV_ATAC")
INPUT_DIR = BASE / "rpkm"
OUTPUT_DIR = BASE / "plots"
TIMEPOINTS = ("1m", "15m", "30m", "1h", "4h", "8h")
TIME_COLORS = {
    "1m": "#440154",
    "15m": "#414487",
    "30m": "#2a788e",
    "1h": "#22a884",
    "4h": "#7ad151",
    "8h": "#fde725",
}
FILES = {
    ("64", "1m"): "R3Hela_1m64_CGATGT_S5_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("64", "15m"): "R3Hela_15m64_TTAGGC_S1_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("64", "30m"): "R3Hela_30m64_TGACCA_S7_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("64", "1h"): "R3Hela_1h64_ACAGTG_S3_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("64", "4h"): "R3Hela_4h64_GCCAAT_S9_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("64", "8h"): "R3Hela_8h64_CAGATC_S11_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "1m"): "R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "15m"): "R3Hela_15mCPD_TAGCTT_S2_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "30m"): "R3Hela_30mCPD_GGCTAC_S8_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "1h"): "R3Hela_1hCPD_CTTGTA_S4_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "4h"): "R3Hela_4hCPD_AGTCAA_S10_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
    ("CPD", "8h"): "R3Hela_8hCPD_AGTTCC_S12_hg38_primary_assembly_notDS_noUV_ATAC_400windows_rpkm.bed",
}


def calculate_window_means(path: Path) -> pd.DataFrame:
    n = np.zeros(400, dtype=np.int64)
    sums = np.zeros(400, dtype=np.float64)
    zero_counts = np.zeros(400, dtype=np.int64)

    with path.open() as handle:
        for line_number, line in enumerate(handle, start=1):
            fields = line.rstrip().split("\t")
            if len(fields) < 6:
                raise ValueError(f"{path}:{line_number}: expected 6 columns")
            window = int(fields[3].rsplit("_", 1)[1]) - 1
            if not 0 <= window < 400:
                raise ValueError(f"{path}:{line_number}: invalid window {window + 1}")
            rpkm = float(fields[-1])
            n[window] += 1
            sums[window] += rpkm
            zero_counts[window] += rpkm == 0

    if np.any(n == 0):
        raise ValueError(f"{path}: one or more window numbers have no observations")
    if not np.all(n == n[0]):
        raise ValueError(f"{path}: unequal peak counts among windows")

    windows = np.arange(1, 401)
    return pd.DataFrame(
        {
            "window": windows,
            "distance_kb": (windows - 200.5) * 0.05,
            "n_peaks": n,
            "mean_rpkm": sums / n,
            "zero_percent": 100 * zero_counts / n,
        }
    )


def main() -> None:
    missing = [INPUT_DIR / name for name in FILES.values() if not (INPUT_DIR / name).is_file()]
    if missing:
        raise FileNotFoundError("Missing RPKM files:\n" + "\n".join(map(str, missing)))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    for (damage, time), filename in FILES.items():
        data = calculate_window_means(INPUT_DIR / filename)
        data.insert(0, "time", time)
        data.insert(0, "damage", damage)
        results.append(data)

    combined = pd.concat(results, ignore_index=True)
    summary = OUTPUT_DIR / "notDS_noUV_ATAC_400windows_mean_rpkm.tsv"
    combined.to_csv(summary, sep="\t", index=False)

    for damage in ("64", "CPD"):
        fig, ax = plt.subplots(figsize=(12, 6))
        for time in TIMEPOINTS:
            data = combined[
                (combined["damage"] == damage) & (combined["time"] == time)
            ]
            ax.plot(
                data["distance_kb"],
                data["mean_rpkm"],
                color=TIME_COLORS[time],
                linewidth=1.8,
                label=time,
            )
        ax.axvline(0, color="black", linestyle="--", linewidth=1)
        ax.set(
            xlabel="Distance from noUV ATAC peak center (kb)",
            ylabel="Mean notDS RPKM",
            title=f"{damage} notDS mean RPKM around noUV ATAC peaks",
            xlim=(-10, 10),
        )
        ax.grid(alpha=0.25)
        ax.legend(title="Time")
        fig.tight_layout()
        output = OUTPUT_DIR / f"{damage}_notDS_noUV_ATAC_mean_rpkm.png"
        fig.savefig(output, dpi=300, bbox_inches="tight")
        plt.close(fig)
        print(f"Saved: {output}")

    print(f"Saved: {summary}")


if __name__ == "__main__":
    main()
