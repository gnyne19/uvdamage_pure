from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

output_dir = Path(
    "/cta/users/guneyn23/peak_length_distribution"
)
output_dir.mkdir(parents=True, exist_ok=True)

peak_files = {
    "ATAC": "/cta/users/guneyn23/idr_results/HelanoUV_R1_R3_IDR_0.05.narrowPeak",
    "H3K9me3": "/cta/users/guneyn23/encode/ENCFF872YCK.bed",
    "H3K27me3": "/cta/users/guneyn23/encode/ENCFF584RYA.bed",
}

colors = {
    "ATAC": "#d62828",
    "H3K9me3": "#003049",
    "H3K27me3": "#f77f00",
}

for peak_name, peak_file in peak_files.items():

    peaks = pd.read_csv(
        peak_file,
        sep="\t",
        header=None,
        comment="#",
        usecols=[0, 1, 2],
        names=["chrom", "start", "end"],
    )

    peaks["peak_length"] = peaks["end"] - peaks["start"]
    peaks = peaks[peaks["peak_length"] > 0]

    median_length = peaks["peak_length"].median()
    mean_length = peaks["peak_length"].mean()

    fig, ax = plt.subplots(figsize=(8, 5))

    ax.hist(
        peaks["peak_length"],
        bins=60,
        color=colors[peak_name],
        edgecolor="white",
        alpha=0.85,
    )

    ax.axvline(
        median_length,
        color="black",
        linestyle="--",
        label=f"Median = {median_length:.0f} bp",
    )

    ax.set_xlabel("Peak length (bp)")
    ax.set_ylabel("Number of peaks")
    ax.set_title(
        f"{peak_name} peak length distribution "
        f"(n={len(peaks):,})"
    )
    ax.legend()
    ax.grid(axis="y", alpha=0.2)

    fig.tight_layout()

    output_file = (
        output_dir /
        f"{peak_name}_peak_length_distribution.png"
    )

    fig.savefig(output_file, dpi=300, bbox_inches="tight")
    plt.close(fig)

    print(
        peak_name,
        f"n={len(peaks)}",
        f"mean={mean_length:.2f}",
        f"median={median_length:.2f}",
        f"output={output_file}",
    )