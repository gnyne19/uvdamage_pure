import sys
import pandas as pd


real_file = sys.argv[1]
sim_file = sys.argv[2]

result_file = sys.argv[3]

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


print(f"Mean RPKM results written to: {result_file}")

