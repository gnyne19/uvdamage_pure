import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


atac_file = sys.argv[1]
h3k9me3_file = sys.argv[2]
h3k27me3_file = sys.argv[3]

plot_file = sys.argv[4]


atac = pd.read_csv(atac_file, sep="\t")
h3k9me3 = pd.read_csv(h3k9me3_file, sep="\t")
h3k27me3 = pd.read_csv(h3k27me3_file, sep="\t")


x_atac = np.linspace(-10, 10, len(atac))
x_h3k9me3 = np.linspace(-10, 10, len(h3k9me3))
x_h3k27me3 = np.linspace(-10, 10, len(h3k27me3))


plt.figure(figsize=(10, 5))


plt.plot(
    x_atac,
    atac["real_sim_ratio"],
    color="blue",
    label="ATAC"
)

plt.plot(
    x_h3k9me3,
    h3k9me3["real_sim_ratio"],
    color="red",
    label="H3K9me3"
)

plt.plot(
    x_h3k27me3,
    h3k27me3["real_sim_ratio"],
    color="green",
    label="H3K27me3"
)


plt.xlabel("Distance from peak center (kb)")
plt.ylabel("Mean real RPKM / Mean simulated RPKM")
plt.title("CPD Damage Enrichment Around Peak Centers")


plt.axhline(
    y=1,
    color="black",
    linestyle="--"
)


plt.axvline(
    x=0,
    color="gray",
    linestyle="--"
)


plt.text(
    0,
    max(
        atac["real_sim_ratio"].max(),
        h3k9me3["real_sim_ratio"].max(),
        h3k27me3["real_sim_ratio"].max()
    ),
    "Peak center",
    color="gray",
    ha="left",
    va="bottom"
)


plt.xlim(-10, 10)
plt.xticks([-10, -5, 0, 5, 10])


plt.legend()

plt.tight_layout()
plt.savefig(plot_file, dpi=300)
plt.close()


print(f"Combined line plot written to: {plot_file}")
