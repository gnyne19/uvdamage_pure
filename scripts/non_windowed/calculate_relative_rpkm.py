#!/usr/bin/env python3
"""Calculate normal RPKM first, then 1m-relative RPKM.

This follows the existing project scripts:
  RPKM = count * 1e9 / (total damage records * interval length)
  relative RPKM = (1m RPKM - timepoint RPKM) / 1m RPKM

Normal RPKM files retain the complete overlap row and append RPKM rounded to
two decimals. Relative files retain the complete timepoint overlap row and
replace the appended RPKM with relative RPKM rounded to two decimals.
"""

import argparse
from pathlib import Path


BASE = Path("/cta/users/guneyn23")
NON_WINDOWED_DIR = BASE / "non_windowed"
OVERLAP_DIR = NON_WINDOWED_DIR / "nonwindowed_overlaps"
NORMAL_1M_DIR = OVERLAP_DIR / "normal_peak_overlaps_1m"
OUTPUT_DIR = NON_WINDOWED_DIR / "nonwindowed_rpkm"
RPKM_DIR = OUTPUT_DIR / "rpkm"
RELATIVE_DIR = OUTPUT_DIR / "relative_rpkm"

PEAK_SETS = (
    "noUV_IDR_ATAC",
    "4h_UV_specific",
    "4h_noUV_specific",
    "8h_UV_specific",
    "8h_noUV_specific",
)
TIMES = ("1m", "15m", "30m", "1h", "4h", "8h")
SAMPLES = {
    ("CPD", "1m"): "1mCPD_GATCAG_S6",
    ("CPD", "15m"): "15mCPD_TAGCTT_S2",
    ("CPD", "30m"): "30mCPD_GGCTAC_S8",
    ("CPD", "1h"): "1hCPD_CTTGTA_S4",
    ("CPD", "4h"): "4hCPD_AGTCAA_S10",
    ("CPD", "8h"): "8hCPD_AGTTCC_S12",
    ("64", "1m"): "1m64_CGATGT_S5",
    ("64", "15m"): "15m64_TTAGGC_S1",
    ("64", "30m"): "30m64_TGACCA_S7",
    ("64", "1h"): "1h64_ACAGTG_S3",
    ("64", "4h"): "4h64_GCCAAT_S9",
    ("64", "8h"): "8h64_CAGATC_S11",
}


def damage_file(damage, time, kind):
    stem = f"R3Hela_{SAMPLES[(damage, time)]}_hg38_primary_assembly_DS"
    if kind == "sim":
        return BASE / "damageseq_data/simulation" / f"{stem}_sim.bed"
    return BASE / "damageseq_data" / f"{stem}.bed"


def overlap_file(peak_set, damage, time, kind):
    if peak_set == "noUV_IDR_ATAC" and time == "1m":
        label = "simulated" if kind == "sim" else "real"
        return NORMAL_1M_DIR / f"ATAC_{damage}_{label}_overlap.bed"
    sample = SAMPLES[(damage, time)]
    return OVERLAP_DIR / f"{peak_set}__{sample}__{kind}_overlap.bed"


def rpkm_file(peak_set, damage, time, kind):
    sample = SAMPLES[(damage, time)]
    return RPKM_DIR / f"{peak_set}__{sample}__{kind}_rpkm.bed"


def relative_file(peak_set, damage, time, kind):
    return RELATIVE_DIR / f"{peak_set}__{damage}__{time}__{kind}_relative_rpkm.tsv"


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
            columns = line.rstrip("\n").split("\t")
            start = int(columns[1])
            end = int(columns[2])
            damage_count = int(columns[-1])
            interval_length = end - start
            rpkm = damage_count * 1_000_000_000 / (total_reads * interval_length)
            outfile.write(line.rstrip("\n") + "\t" + f"{rpkm:.2f}" + "\n")


def calculate_relative_rpkm(reference_file, timepoint_file, output_file):
    with open(reference_file) as reference, open(timepoint_file) as timepoint, open(output_file, "w") as outfile:
        reference_lines = [line.rstrip("\n").split("\t") for line in reference if line.strip()]
        timepoint_lines = [line.rstrip("\n").split("\t") for line in timepoint if line.strip()]

        if len(reference_lines) != len(timepoint_lines):
            raise ValueError(
                f"Row count differs: reference={len(reference_lines)}, "
                f"timepoint={len(timepoint_lines)}"
            )

        for row_number, (reference_row, timepoint_row) in enumerate(
            zip(reference_lines, timepoint_lines), start=1
        ):
            if reference_row[:3] != timepoint_row[:3]:
                raise ValueError(f"Peak coordinates differ at row {row_number}")
            reference_rpkm = float(reference_row[-1])
            timepoint_rpkm = float(timepoint_row[-1])
            relative_rpkm = (
                "NA"
                if reference_rpkm == 0
                else f"{(reference_rpkm - timepoint_rpkm) / reference_rpkm:.2f}"
            )
            outfile.write(
                "\t".join(timepoint_row[:-1])
                + "\t"
                + relative_rpkm
                + "\n"
            )


def run(peak_set, damage, kind):
    overlaps = {
        time: overlap_file(peak_set, damage, time, kind) for time in TIMES
    }
    damages = {
        time: damage_file(damage, time, kind) for time in TIMES
    }
    missing = [
        path
        for path in (*overlaps.values(), *damages.values())
        if not path.is_file()
    ]
    empty = [
        path
        for path in overlaps.values()
        if path.is_file() and path.stat().st_size == 0
    ]
    if missing or empty:
        messages = [f"Missing: {path}" for path in missing]
        messages += [f"Empty: {path}" for path in empty]
        raise FileNotFoundError("\n".join(messages))

    RPKM_DIR.mkdir(parents=True, exist_ok=True)
    RELATIVE_DIR.mkdir(parents=True, exist_ok=True)

    for time in TIMES:
        total_reads = count_reads(damages[time])
        output = rpkm_file(peak_set, damage, time, kind)
        print(
            f"Counted {total_reads} damage records from {damages[time]}",
            flush=True,
        )
        calculate_rpkm(overlaps[time], output, total_reads)
        print(
            f"Calculated RPKM from {overlaps[time]} and wrote the results "
            f"to {output}",
            flush=True,
        )

    reference = rpkm_file(peak_set, damage, "1m", kind)
    for time in TIMES[1:]:
        output = relative_file(peak_set, damage, time, kind)
        calculate_relative_rpkm(
            reference,
            rpkm_file(peak_set, damage, time, kind),
            output,
        )
        print(f"Written: {output}", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--peak-set", choices=PEAK_SETS, required=True)
    parser.add_argument("--damage", choices=("CPD", "64"), required=True)
    parser.add_argument("--kind", choices=("real", "sim"), required=True)
    args = parser.parse_args()
    run(args.peak_set, args.damage, args.kind)


if __name__ == "__main__":
    main()
