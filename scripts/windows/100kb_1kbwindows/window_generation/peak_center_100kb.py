import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file) as infile, open(output_file, "w") as outfile:

    peak_number = 1

    for line in infile:
        if not line.strip():
            continue

        columns = line.strip().split("\t")

        chromosome = columns[0]
        start = int(columns[1])
        summit_offset = int(columns[9])

        center = start + summit_offset

        new_start = center - 50000
        new_end = center + 50000

        if new_start < 0:
            new_start = 0
            new_end = 100000

        outfile.write(
            chromosome + "\t" +
            str(new_start) + "\t" +
            str(new_end) + "\t" +
            "peak_" + str(peak_number) + "\n"
        )

        peak_number += 1
