
real_count_file = "/cta/users/guneyn23/peak_center_20kb/overlaps/CPD_damage_overlapping_WATAC_peaks.bed"
sim_count_file = "/cta/users/guneyn23/peak_center_20kb/overlaps/CPD_sim_overlapping_WATAC_peaks.bed"


real_damage_file = "/cta/users/guneyn23/damageseq_data/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS.bed"
sim_damage_file = "/cta/users/guneyn23/damageseq_data/simulation/R3Hela_1mCPD_GATCAG_S6_hg38_primary_assembly_DS_sim.bed"

real_rpkm_file = "/cta/users/guneyn23/rpkm/real_damage_rpkm.bed"
sim_rpkm_file = "/cta/users/guneyn23/rpkm/sim_damage_rpkm.bed"

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

