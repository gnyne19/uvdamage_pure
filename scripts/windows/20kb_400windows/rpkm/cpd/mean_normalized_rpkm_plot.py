import pandas as pd
import matplotlib.pyplot as plt


real_file = "/cta/users/guneyn23/rpkm/real_damage_rpkm.bed"
sim_file = "/cta/users/guneyn23/rpkm/sim_damage_rpkm.bed"

result_file = "/cta/users/guneyn23/rpkm/mean_rpkm_ratio.tsv"
plot_file = "/cta/users/guneyn23/rpkm/mean_rpkm_ratio.png"

number_of_windows = 400


real = pd.read_csv(real_file, sep="\t", header=None)
sim = pd.read_csv(sim_file, sep="\t", header=None)


real["rpkm"] = real.iloc[:, -1]
sim["rpkm"] = sim.iloc[:, -1]


real["window"] = (real.index % number_of_windows) + 1
sim["window"] = (sim.index % number_of_windows) + 1


mean_real = real.groupby("window")["rpkm"].mean()
mean_sim = sim.groupby("window")["rpkm"].mean()


result = pd.DataFrame({
    "window": mean_real.index,
    "mean_real_rpkm": mean_real.values,
    "mean_sim_rpkm": mean_sim.values
})


result["real_sim_ratio"] = (
    result["mean_real_rpkm"]
    / result["mean_sim_rpkm"]
)


result.to_csv(
    result_file,
    sep="\t",
    index=False
)


plt.figure(figsize=(10, 5))

plt.plot(
    result["window"],
    result["real_sim_ratio"]
)

plt.xlabel("Window number")
plt.ylabel("Mean real RPKM / Mean simulated RPKM")
plt.title("Damage enrichment around ATAC peak centers")

plt.axhline(y=1, linestyle="--")

plt.axvline(
    x=200.5,
    color="gray",
    linestyle="--"
)

plt.text(
    200.5,
    result["real_sim_ratio"].max(),
    "Peak center",
    color="gray",
    ha="left",
    va="bottom"
)

plt.tight_layout()
plt.savefig(plot_file, dpi=300)
plt.close()


print(f"Mean RPKM results written to: {result_file}")
print(f"Line plot written to: {plot_file}")