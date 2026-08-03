import sys



real_count_file = sys.argv[1]
sim_count_file = sys.argv[2]

real_damage_file = sys.argv[3]
sim_damage_file = sys.argv[4]

real_rpkm_file = sys.argv[5]
sim_rpkm_file = sys.argv[6]

window_length = 50


def count_reads(damage_file):

    total_reads = 0

    with open(damage_file) as infile:

        for line in infile:
            if not line.strip():
                continue

            total_reads += 1

    return total_reads


def calculate_rpkm(input_file, output_file, total_reads):

    with open(input_file) as infile, open(output_file, "w") as outfile:

        for line in infile:
            if not line.strip():
                continue

            columns = line.strip().split("\t")
            damage_count = int(columns[-1])

            rpkm = (
                damage_count * 1_000_000_000
            ) / (
                total_reads * window_length
            )

            outfile.write(
                line.strip()
                + "\t"
                + f"{rpkm:.2f}"
                + "\n"
            )


real_total_reads = count_reads(real_damage_file)
sim_total_reads = count_reads(sim_damage_file)

print(
    f"Counted {real_total_reads} real damage records "
    f"from {real_damage_file}"
)

print(
    f"Counted {sim_total_reads} simulated damage records "
    f"from {sim_damage_file}"
)


calculate_rpkm(
    real_count_file,
    real_rpkm_file,
    real_total_reads
)

print(
    f"Calculated real damage RPKM from {real_count_file} "
    f"and wrote the results to {real_rpkm_file}"
)


calculate_rpkm(
    sim_count_file,
    sim_rpkm_file,
    sim_total_reads
)

print(
    f"Calculated simulated damage RPKM from {sim_count_file} "
    f"and wrote the results to {sim_rpkm_file}"
)
