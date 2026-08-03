import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


atac_file = sys.argv[1]
h3k9me3_file = sys.argv[2]
h3k27me3_file = sys.argv[3]

result_file = sys.argv[4]
plot_file = sys.argv[5]
plot_title = sys.argv[6]


number_of_windows = 400


def baseline_normalize(file_path, region_name):
    data = pd.read_csv(file_path, sep="\t")

    values = data["real_sim_ratio"].to_numpy()

    if len(values) != number_of_windows:
        raise ValueError(
            f"{region_name}: Expected 400 windows, "
            f"but found {len(values)}."
        )

    # Window centers from -10 kb to +10 kb.
    # Each window is 50 bp = 0.05 kb.
    distance_kb = (
        np.arange(number_of_windows) + 0.5
    ) * 0.05 - 10

    # Use both outer regions as the baseline:
    # -10 to -6 kb and +6 to +10 kb.
    baseline_mask = (
        ((distance_kb >= -10) & (distance_kb <= -6)) |
        ((distance_kb >= 6) & (distance_kb <= 10))
    )

    baseline = values[baseline_mask].mean()

    if baseline == 0:
        raise ValueError(
            f"{region_name}: Baseline is zero, "
            "so normalization cannot be performed."
        )

    normalized = values / baseline

    result = pd.DataFrame({
        "distance_kb": distance_kb,
        "real_sim_ratio": values,
        "baseline_normalized_ratio": normalized,
        "region": region_name
    })

    return result, baseline


atac, atac_baseline = baseline_normalize(
    atac_file,
    "ATAC"
)

h3k9me3, h3k9me3_baseline = baseline_normalize(
    h3k9me3_file,
    "H3K9me3"
)

h3k27me3, h3k27me3_baseline = baseline_normalize(
    h3k27me3_file,
    "H3K27me3"
)


combined = pd.concat(
    [atac, h3k9me3, h3k27me3],
    ignore_index=True
)

combined.to_csv(
    result_file,
    sep="\t",
    index=False
)


plt.figure(figsize=(10, 5))


plt.plot(
    atac["distance_kb"],
    atac["baseline_normalized_ratio"],
    color="blue",
    label="ATAC"
)

plt.plot(
    h3k9me3["distance_kb"],
    h3k9me3["baseline_normalized_ratio"],
    color="red",
    label="H3K9me3"
)

plt.plot(
    h3k27me3["distance_kb"],
    h3k27me3["baseline_normalized_ratio"],
    color="green",
    label="H3K27me3"
)


# Baseline reference.
plt.axhline(
    y=1,
    color="black",
    linestyle="--"
)

# Peak center.
plt.axvline(
    x=0,
    color="gray",
    linestyle="--"
)


maximum_value = max(
    atac["baseline_normalized_ratio"].max(),
    h3k9me3["baseline_normalized_ratio"].max(),
    h3k27me3["baseline_normalized_ratio"].max()
)

plt.text(
    0,
    maximum_value,
    "Peak center",
    color="gray",
    ha="left",
    va="bottom"
)


plt.xlabel("Distance from peak center (kb)")
plt.ylabel("Baseline-normalized real/sim ratio")
plt.title(plot_title)

plt.xlim(-10, 10)
plt.xticks([-10, -5, 0, 5, 10])

plt.legend()
plt.tight_layout()

plt.savefig(
    plot_file,
    dpi=300
)

plt.close()


print("ATAC baseline:", atac_baseline)
print("H3K9me3 baseline:", h3k9me3_baseline)
print("H3K27me3 baseline:", h3k27me3_baseline)

print("Result file:", result_file)
print("Plot file:", plot_file)
