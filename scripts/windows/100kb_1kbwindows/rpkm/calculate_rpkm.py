import sys


count_file = sys.argv[1]
damage_file = sys.argv[2]
rpkm_file = sys.argv[3]

window_length = 1000


def count_reads(input_file):

    total_reads = 0

    with open(input_file) as infile:

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


total_reads = count_reads(damage_file)

print(
    f"Counted {total_reads} damage records "
    f"from {damage_file}"
)

calculate_rpkm(
    count_file,
    rpkm_file,
    total_reads
)

print(
    f"Calculated RPKM from {count_file} "
    f"and wrote the results to {rpkm_file}"
)
