import csv
import sys
from collections import defaultdict
from pathlib import Path


real_rpkm_file = Path(sys.argv[1])
sim_rpkm_file = Path(sys.argv[2])
output_tsv = Path(sys.argv[3])


def calculate_window_means(path):
    sums = defaultdict(float)
    counts = defaultdict(int)

    with path.open() as infile:
        for line_number, columns in enumerate(
            csv.reader(infile, delimiter="\t"),
            start=1,
        ):
            if not columns:
                continue
            if len(columns) < 6:
                raise ValueError(
                    f"{path}, line {line_number}: fewer than 6 columns"
                )

            window = int(columns[3].rsplit("_", 1)[-1])
            rpkm = float(columns[-1])

            sums[window] += rpkm
            counts[window] += 1

    means = {
        window: sums[window] / counts[window]
        for window in counts
    }

    expected_windows = set(range(1, 401))
    if set(means) != expected_windows:
        missing = sorted(expected_windows - set(means))
        raise ValueError(f"{path}: missing windows: {missing}")

    return means


mean_real = calculate_window_means(real_rpkm_file)
mean_sim = calculate_window_means(sim_rpkm_file)

output_tsv.parent.mkdir(parents=True, exist_ok=True)

with output_tsv.open("w", newline="") as outfile:
    writer = csv.writer(outfile, delimiter="\t")
    writer.writerow(
        [
            "window",
            "mean_real_rpkm",
            "mean_sim_rpkm",
            "real_sim_ratio",
        ]
    )

    for window in range(1, 401):
        real = mean_real[window]
        sim = mean_sim[window]
        ratio = real / sim if sim != 0 else float("nan")
        writer.writerow([window, real, sim, ratio])

print(f"Written: {output_tsv}")
