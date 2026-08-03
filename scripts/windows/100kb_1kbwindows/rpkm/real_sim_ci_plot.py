import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


damage_type = sys.argv[1]
input_dir = Path(sys.argv[2])
output_dir = Path(sys.argv[3])

number_of_windows = 100

colors = {
    "ATAC": "#d62828",
    "H3K9me3": "#003049",
    "H3K27me3": "#f77f00",
}


def calculate_window_ratios(real_file, sim_file):
    counts = np.zeros(number_of_windows, dtype=np.int64)
    sums = np.zeros(number_of_windows, dtype=np.float64)
    sum_squares = np.zeros(number_of_windows, dtype=np.float64)
    skipped_zero_sim = np.zeros(number_of_windows, dtype=np.int64)

    with open(real_file) as real_in, open(sim_file) as sim_in:
        for line_number, (real_line, sim_line) in enumerate(
            zip(real_in, sim_in, strict=True), start=1
        ):
            real_columns = real_line.rstrip("\n").split("\t")
            sim_columns = sim_line.rstrip("\n").split("\t")

            if real_columns[:4] != sim_columns[:4]:
                raise ValueError(
                    f"Real/sim window mismatch at line {line_number}: "
                    f"{real_columns[:4]} != {sim_columns[:4]}"
                )

            window = int(real_columns[3].rsplit("_", 1)[1]) - 1
            real_rpkm = float(real_columns[-1])
            sim_rpkm = float(sim_columns[-1])

            if sim_rpkm == 0:
                skipped_zero_sim[window] += 1
                continue

            ratio = real_rpkm / sim_rpkm
            counts[window] += 1
            sums[window] += ratio
            sum_squares[window] += ratio * ratio

    mean_ratio = sums / counts
    variance = (
        sum_squares - (sums * sums / counts)
    ) / (counts - 1)
    standard_error = np.sqrt(variance / counts)
    ci_margin = 1.96 * standard_error

    return pd.DataFrame({
        "window": np.arange(1, number_of_windows + 1),
        "distance_kb": np.arange(number_of_windows) - 49.5,
        "real_sim_ratio": mean_ratio,
        "ci95_lower": mean_ratio - ci_margin,
        "ci95_upper": mean_ratio + ci_margin,
        "n_ratios": counts,
        "skipped_zero_sim": skipped_zero_sim,
    })


output_dir.mkdir(parents=True, exist_ok=True)
results = []

for region in ["ATAC", "H3K27me3", "H3K9me3"]:
    real_file = input_dir / f"{region}_{damage_type}_real_rpkm.bed"
    sim_file = input_dir / f"{region}_{damage_type}_simulated_rpkm.bed"

    result = calculate_window_ratios(real_file, sim_file)
    result.insert(0, "region", region)
    results.append(result)

combined = pd.concat(results, ignore_index=True)
result_file = output_dir / f"{damage_type}_window_real_sim_ratio_ci95.tsv"
combined.to_csv(result_file, sep="\t", index=False)

plt.figure(figsize=(12, 6))

for region in ["ATAC", "H3K27me3", "H3K9me3"]:
    data = combined[combined["region"] == region]
    x = data["distance_kb"].to_numpy()
    ratio = data["real_sim_ratio"].to_numpy()
    lower = data["ci95_lower"].to_numpy()
    upper = data["ci95_upper"].to_numpy()

    plt.plot(x, ratio, color=colors[region], label=region)
    plt.fill_between(x, lower, upper, color=colors[region], alpha=0.2)

plt.axhline(y=1, color="black", linestyle="--")
plt.axvline(x=0, color="gray", linestyle="--")
plt.xlabel("Distance from peak center (kb)")
plt.ylabel("Real/sim RPKM ratio")
plt.title(f"{damage_type} real/sim RPKM ratio with 95% CI")
plt.xlim(-50, 50)
plt.xticks([-50, -25, 0, 25, 50])
plt.grid(True, linestyle="--", alpha=0.6)
plt.legend()
plt.tight_layout()

plot_file = output_dir / f"{damage_type}_window_real_sim_ratio_ci95.png"
plt.savefig(plot_file, dpi=300)
plt.close()

print(f"Result file: {result_file}")
print(f"Plot file: {plot_file}")
