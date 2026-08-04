# UV Damage and Chromatin Accessibility Analysis

This repository contains the analysis workflow developed during the Sabancı
University PURE Summer 2026 program. It combines ATAC-seq and Damage-seq to
study UV-induced DNA damage and repair across open and closed chromatin states.

## Final workflow

The canonical analysis proceeds in the following order:

1. **ATAC-seq processing and peak calling**
   - `slurms/atac_analysis_array/atac_array.slurm`
   - `slurms/atac_analysis_array/macs3_nucleosomefree_array.slurm`
   - `slurms/atac_single_scripts/` contains the same processing stages as
     individually runnable jobs for step-by-step execution and traceability.
   - Supporting R code: `scripts/atac_analysis/`
2. **Replicate consistency with IDR**
   - `slurms/idr.slurm`
   - `slurms/idr_finalnarrowpeak.slurm`
3. **Damage profiles around chromatin features**
   - 20 kb regions divided into 400 windows (50 bp/window)
   - 20 kb regions divided into 100 windows (200 bp/window)
   - 100 kb regions divided into 100 windows (1 kb/window)
4. **Relative-repair profiles**
   - `scripts/windows/shared_relative_repair/positive_relative_mean_profiles.py`
   - Final profiles were calculated at both 20 kb and 100 kb scales.
5. **Background-profile analysis**
   - `slurms/background_profile/` contains the notDS control workflow,
     including strand-specific comparisons.
6. **Differential accessibility**
   - Final analyses: 250-bp summit-centered peaks and nucleosome-free regions
   - `slurms/diffbind/run_diffbind_250_nfr.slurm`
   - `slurms/diffbind/postprocess_diffbind_250_nfr.slurm`
   - Supporting R code: `scripts/diffbind/`
7. **Damage profiles at differential-accessibility regions**
   - Full-width (`no_summits`) differential regions are centered on their
     genomic interval midpoint.
   - Profiles are calculated across either 20 kb (100 x 200-bp windows) or
     100 kb (100 x 1-kb windows).
   - Real Damage-seq signal, simulated signal, and their real/simulated ratio
     are summarized separately for noUV-higher and UV-timepoint-higher regions.
   - Workflow files: `slurms/diffbind/differential_peak_profiles/`
   - RPKM calculation: `scripts/diffbind/differential_peak_profiles/`

## ATAC-seq workflow and retained alternatives

`slurms/atac_analysis_array/atac_array.slurm` is the canonical ATAC-seq
workflow used for the final analysis. It performs read-quality control,
trimming, alignment, BAM processing and filtering, quality assessment,
Tn5 shifting, signal-track generation, and MACS3 peak calling. The scripts in
`slurms/atac_single_scripts/` preserve these stages as separate jobs so that an
individual stage can be inspected or rerun without restarting the full array.
`bowtie2_hg38_index.slurm` is the reference-index preparation step.

MACS3 peaks were carried forward into the downstream analyses. MACS2 and
HMMRATAC were tested during method development, so `macs2.slurm` and
`hmmr_peakcall.slurm` are retained for traceability, but their peak calls were
not used in the subsequent IDR, window-profile, relative-repair, or DiffBind
analyses.

## Window-profile generation

For the 100 kb/1 kb-window analysis,
`peak_center_100kb_overlap.slurm` generates the initial real and simulated
damage-overlap tables, and `peak_center_100kb_rpkm.slurm` converts those tables
to RPKM profiles. These initial files are also prerequisites of the retained
three-chromatin-state workflow.

For the 20 kb/400-window 1-minute CPD ATAC data,
`atac_real_sim_rpkm.slurm` generates the real and simulated RPKM files. The
older standalone ATAC mean-plot job was not used for the final figures and is
therefore not retained. The H3K9me3 and H3K27me3 1-minute CPD RPKM files and
mean real/simulated profiles are generated separately by the corresponding
`H3k9me3_*_rpkm.slurm` and `H3k27me3_*_rpkm.slurm` jobs.

The 1-minute 6-4PP workflow is organized differently:
`damage_64_rpkm.slurm` is an array job that calculates both the RPKM files and
mean real/simulated profiles for ATAC, H3K9me3, and H3K27me3.

For the later ATAC time points, `noUV_atac_damage_all.slurm` and
`noUV_atac_sim_damage_all.slurm` generate the real and simulated overlap files.
`notebooks/damage profiles/noUV_atac_damage_rpkm.ipynb` converts these overlap
counts to the 15-minute, 30-minute, 1-hour, 4-hour, and 8-hour ATAC RPKM files.

For the later heterochromatin time points,
`heterochromatin_400windows_mean_20array.slurm`, together with
`calculate_heterochromatin_window_means.py`, generates the 15-minute,
30-minute, 1-hour, 4-hour, and 8-hour mean real/simulated profiles for H3K9me3
and H3K27me3. The 1-minute files provide the initial time point in the
all-time-point plots.

## Repository structure

- `slurms/`: SLURM job definitions, organized by analysis stage.
- `scripts/`: R and Python implementations used by the SLURM workflows.
- `notebooks/`: exploratory and comparative analyses retained as a record of
  the analysis development process. The canonical runnable workflow is defined
  by the SLURM files and scripts listed above.

## Notebook scope

The notebooks document distinct comparisons performed during the project,
including confidence-interval choices, real/simulated normalization,
relative-repair definitions, central-window distributions, and alternative
window resolutions. They are preserved for traceability but are not presented
as separate steps in the final pipeline.

## Local RStudio statistical comparisons

Two additional R scripts were run locally in RStudio to compare non-windowed,
peak-level RPKM distributions among ATAC, H3K9me3, and H3K27me3 regions:

- `scripts/raincloud/dunn_rpkm_plot.R`: Dunn pairwise comparisons with Benjamini-Hochberg
  adjusted p-values.
- `scripts/raincloud/wilcoxon_rank_sum_plot.R`: pairwise Wilcoxon rank-sum comparisons
  with Benjamini-Hochberg adjusted p-values.
The scripts retain the local Windows paths used in RStudio
(`C:/pure_project`) and expect six prepared input tables containing
`real_rpkm` and `sim_rpkm` columns. The paths must be changed before running
the scripts on another computer. Input tables and generated figures are not
included in this repository.

## Summary-statistic choice

Damage-count and RPKM profiles contain a high proportion of zero-valued
observations. Window medians were therefore frequently zero and did not provide
an informative profile of the underlying signal. Median-based damage/RPKM
analyses were excluded from the final repository, and the final window profiles
use mean-based summaries. The median reported by the peak-length utility is
unrelated to this choice and is retained only as a descriptive statistic for
peak widths.

## DiffBind selection

Several DiffBind parameterizations were tested during development. The final
workflow uses the 250-bp summit-centered and nucleosome-free (NFR) analyses;
the full-width `no_summits` alternative is also retained for comparison.
Significant DESeq2 regions are split into noUV-specific and
UV-timepoint-specific BED files during post-processing.

## Differential-peak damage profiles

The full-width `no_summits` DiffBind results are also used to examine
Damage-seq signal around differential-accessibility regions. In this workflow,
"noUV-higher" and "UV-timepoint-higher" describe the direction of the ATAC-seq
DESeq2 contrast; they do not mean that a region is present exclusively in one
condition.

The profile workflow currently uses the significant 4-hour and 8-hour DESeq2
BED files. Each differential interval is represented by its genomic midpoint,
then expanded and divided into 100 equal windows. Two profile scales are
available:

- `create_20kb_windows.slurm`: midpoint +/-10 kb, 200 bp per window.
- `create_100kb_windows.slurm`: midpoint +/-50 kb, 1 kb per window.

For either scale, run the window, overlap, and RPKM jobs in that order. The
overlap jobs count real and simulated Damage-seq records in each window with
`bedtools intersect`. The shared Python script calculates:

`RPKM = overlap count x 10^9 / (total damage records x window length)`

The plotting notebooks contain separate sections for real RPKM, simulated
RPKM, and real/simulated profiles:

- `notebooks/damage profiles/differential_peak/no_summits_differential_damage_profiles_20kb.ipynb`
- `notebooks/damage profiles/differential_peak/no_summits_differential_damage_profiles_100kb.ipynb`

`heterochromatin_overlap.slurm` is a separate descriptive analysis that reports
how many noUV-higher and UV-timepoint-higher regions overlap the H3K9me3 and
H3K27me3 reference BED files. It is not required for generating the damage
profiles.

## Data availability and paths

Large sequencing files, reference genomes, intermediate files, logs, and
generated results are not included. The SLURM files preserve the cluster paths
used during the project (`/cta/users/guneyn23`); these paths and Conda
environment names must be adapted before running the workflow elsewhere.
