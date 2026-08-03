#!/usr/bin/env python3
"""Plot raw notDS RPKM with seaborn's automatic mean and 95% CI."""

import argparse
import gc
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


BASE = Path("/cta/users/guneyn23")
ATAC_DIR = BASE / "peak_center_20kb/notDS_noUV_ATAC/rpkm"
HETERO_DIR = BASE / "peak_center_20kb/notDS_3states/rpkm"
OUT = BASE / "peak_center_20kb/notDS_3states/raw_seaborn_ci95_plots"
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
COLORS = {
    "1m": "#01befe",
    "15m": "#ffdd00",
    "30m": "#ff7d00",
    "1h": "#ff006d",
    "4h": "#adff02",
    "8h": "#8f00ff",
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
DISTANCE_KB = (np.arange(1, 401, dtype=np.float32) - 200.5) * 0.05


def rpkm_path(region: str, damage: str, time: str) -> Path:
    sample = SAMPLES[(damage, time)]
    if region == "ATAC":
        return ATAC_DIR / f"{sample}_notDS_noUV_ATAC_400windows_rpkm.bed"
    return HETERO_DIR / f"{sample}_notDS_{region}_400windows_rpkm.bed"


def load_raw_rpkm(path: Path) -> pd.DataFrame:
    # Read the raw RPKM column only. Window rows occur in repeating 1..400
    # order for every peak, so distance can be assigned without retaining the
    # large string-valued peak_window column.
    data = pd.read_csv(
        path,
        sep="\t",
        header=None,
        usecols=[5],
        names=["rpkm"],
        dtype={"rpkm": np.float32},
    )
    if len(data) % 400:
        raise ValueError(f"{path}: row count is not divisible by 400")
    data["distance_kb"] = np.tile(DISTANCE_KB, len(data) // 400)
    return data


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("region", choices=("ATAC", "H3K9me3", "H3K27me3"))
    parser.add_argument("damage", choices=("64", "CPD"))
    parser.add_argument(
        "--n-boot",
        type=int,
        default=100,
        help="Number of seaborn bootstrap resamples (default: 100)",
    )
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(10, 5))

    for time in TIMES:
        path = rpkm_path(args.region, args.damage, time)
        if not path.is_file():
            raise FileNotFoundError(path)
        print(f"Reading raw RPKM: {path}", flush=True)
        data = load_raw_rpkm(path)

        # Seaborn receives every raw peak-window RPKM observation. It computes
        # the mean estimator and bootstrap 95% CI automatically per window.
        sns.lineplot(
            data=data,
            x="distance_kb",
            y="rpkm",
            estimator="mean",
            errorbar=("ci", 95),
            n_boot=args.n_boot,
            seed=42,
            color=COLORS[time],
            label=time,
            linewidth=1.5,
            ax=ax,
        )
        del data
        gc.collect()

    ax.axvline(0, color="gray", linestyle="--", linewidth=1)
    ax.set_xlim(-10, 10)
    ax.set_ylim(0.18, 0.46)
    ax.set_xlabel(f"Distance from {args.region} center (kb)")
    ax.set_ylabel("notDS RPKM")
    ax.set_title(f"{args.region} {args.damage} — raw RPKM, mean with 95% CI")
    ax.legend(title="Time")
    ax.grid(alpha=0.2)
    fig.tight_layout()

    output = OUT / f"{args.region}_{args.damage}_notDS_raw_seaborn_ci95.png"
    fig.savefig(output, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {output}", flush=True)


if __name__ == "__main__":
    main()
