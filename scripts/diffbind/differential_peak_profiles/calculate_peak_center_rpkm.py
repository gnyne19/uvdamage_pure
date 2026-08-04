import sys


overlap_file = sys.argv[1]
damage_file = sys.argv[2]
output_file = sys.argv[3]


def count_records(file_path):
    with open(file_path) as input_file:
        return sum(1 for line in input_file if line.strip())


total_records = count_records(damage_file)

if total_records == 0:
    raise ValueError(f"Damage file is empty: {damage_file}")

with open(overlap_file) as input_file, open(output_file, "w") as output:
    for line in input_file:
        if not line.strip():
            continue

        columns = line.rstrip("\n").split("\t")
        window_length = int(columns[2]) - int(columns[1])
        overlap_count = int(columns[-1])
        rpkm = overlap_count * 1_000_000_000 / (total_records * window_length)

        output.write(line.rstrip("\n") + "\t" + f"{rpkm:.2f}\n")

print(f"Damage records: {total_records}")
print(f"RPKM output: {output_file}")
