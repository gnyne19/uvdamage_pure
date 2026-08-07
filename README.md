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
   - `scripts/windows/positive_relative_repair/positive_relative_mean_profiles.py`
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
   - The current count-normalized analysis pools the raw overlap counts in
     each window, divides each window by the total count of its own time-point
     profile, and uses the normalized 1-minute profile as the persistence
     reference. This analysis does not use RPKM.
   - Real and simulated profiles are analyzed separately, with an additional
     real/simulated spatial correction. The earlier RPKM workflow is retained
     as a separate analysis rather than mixed with the count-share results.
   - Workflow files: `slurms/diffbind/differential_peak_profiles/`
   - Count-share notebooks: `notebooks/count_normalize_profiles/`
   - Retained RPKM calculation: `scripts/diffbind/differential_peak_profiles/`
8. **Non-windowed peak-level repair distributions**
   - `slurms/non_windowed_overlaps/` and
     `scripts/non_windowed/calculate_relative_rpkm.py` calculate peak-level
     real/simulated RPKM and 1-minute-relative repair distributions.

## Recent analysis additions

- Count-share damage profiles and 1-minute-referenced persistence analyses were
  added for ATAC, H3K9me3, H3K27me3, and the four full-width differential-peak
  groups (4h noUV-specific, 4h-specific, 8h noUV-specific, and 8h-specific).
  The differential-peak analysis is available at both 20 kb/100 windows and
  100 kb/100 windows. These notebooks pool the final overlap-count column and
  do not calculate or use RPKM.
- Differential-peak plots use common y-axis limits across peak groups and
  damage types so that profile amplitudes can be compared directly: 0.50–1.40%
  for normalized window damage, -45–45% for relative repair, and 0.65–1.45
  for persistence and real/simulated ratio plots.
- Final filtered damage-profile cells were added to the existing 20 kb and
  100 kb notebooks. They retain 15m/1h/4h/8h for CPD and 15m/30m/1h for
  6-4PP while preserving the earlier figures.
- Positive relative repair is calculated per window before taking the mean;
  negative real values are excluded. The workflow supports both 20 kb/400
  windows and 100 kb/100 windows. The calculation and filtered-plot scripts
  are in `scripts/windows/positive_relative_repair/`, with launch jobs in the
  corresponding `slurms/20kb_400windows/plotting/` and
  `slurms/100kb_1kbwindows/plotting/` directories.
- `notebooks/relative repair/nonwindowed_relative_rpkm_distribution.ipynb`
  first sums the final `bedtools intersect -c` column to compare total overlap
  counts from 1m to 8h without RPKM normalization. It also plots real and
  simulated peak-level relative-RPKM distributions separately and reports the
  initial peak count, excluded negative count, and excluded percentage.
- `fully_repaired_timepoint_venn.slurm` extracts peaks with relative RPKM = 1
  and performs reciprocal full-overlap comparisons (`bedtools intersect -f 1
  -F 1`). The same non-windowed notebook draws the early 15m/30m/1h and late
  1h/4h/8h Venn diagrams from the resulting BED files; plotting is not run by
  SLURM.

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

### Count-share normalization

The current persistence analysis starts directly from the final count column
of the `bedtools intersect -c` overlap files. It does not use the RPKM files.
For region group (r), damage type (d), data kind (k) (real or simulated),
time point (t), and window (w), the pooled window count is:

`C(r,d,k,t,w) = sum of overlap counts for window w across all regions`

The total for that complete 100-window profile is:

`T(r,d,k,t) = sum over windows C(r,d,k,t,w)`

The normalized damage share and the percentage shown in the upper profile
plots are:

`damage_share(r,d,k,t,w) = C(r,d,k,t,w) / T(r,d,k,t)`

`damage_percent(r,d,k,t,w) = 100 x damage_share(r,d,k,t,w)`

Consequently, every time-point profile sums to 1 as a share, or 100% as a
percentage. The normalization controls for differences in the total number of
overlapping Damage-seq records between time points and emphasizes where damage
is distributed within the profile. It does not measure the absolute amount of
damage remaining genome-wide. Because all windows have the same width within
each analysis, no RPKM or window-length correction is needed for this
within-profile comparison.

### Persistence and relative repair

The 1-minute normalized profile is the window-specific reference. Persistence
at a later time point is calculated independently for every window:

`persistence_ratio(t,w) = damage_share(t,w) / damage_share(1m,w)`

Using `damage_percent` gives exactly the same ratio because the factor of 100
cancels. Interpretation is:

- `persistence_ratio = 1`: the window has the same relative share as at 1m.
- `persistence_ratio > 1`: the window represents a larger fraction of the
  remaining profile than at 1m; this is relative persistence or slower
  relative depletion.
- `persistence_ratio < 1`: the window represents a smaller fraction than at
  1m; this is relative depletion or faster relative repair.

The paired figures show the 1m and selected time-point damage-share profiles
in the upper row and `time point / 1m` persistence in the lower row. Since the
input profiles are normalized separately at every time point, persistence is
a spatial redistribution metric, not the fraction of the original absolute
lesion count that remains.

The relative-repair view is the same comparison expressed as a percentage:

`relative_repair_percent(t,w) = 100 x (damage_share(1m,w) - damage_share(t,w)) / damage_share(1m,w)`

Equivalently:

`relative_repair_percent = 100 x (1 - persistence_ratio)`

Positive values indicate relative depletion/faster relative repair; zero
indicates no relative change; negative values indicate relative persistence or
enrichment compared with the 1m spatial distribution.

### Simulation-corrected persistence

Real and simulated profiles are first normalized independently by their own
100-window totals. Their spatial enrichment ratio is then:

`real_sim_ratio(t,w) = real_damage_share(t,w) / simulated_damage_share(t,w)`

The simulation-corrected persistence ratio is:

`sim_corrected_persistence(t,w) = real_sim_ratio(t,w) / real_sim_ratio(1m,w)`

This second ratio asks whether real damage becomes relatively more or less
enriched than the simulated background at a window after accounting for the
initial 1m enrichment pattern. Values above 1 indicate increased relative
persistence after simulation correction; values below 1 indicate relative
depletion. It remains a normalized spatial metric and should not be interpreted
as absolute repair kinetics.

The count-share notebooks are:

- `notebooks/count_normalize_profiles/damage_profiles_20kb_100windows.ipynb`
- `notebooks/count_normalize_profiles/damage_profiles_relative_repair_100kb_1kbwindows.ipynb`
- `notebooks/count_normalize_profiles/damage_profiles_diffpeaks_20kb_100windows.ipynb`
- `notebooks/count_normalize_profiles/damage_profiles_diffpeaks_100kb_100window.ipynb`

The first two cover ATAC, H3K9me3, and H3K27me3. The last two apply the same
calculation and plotting workflow to the four 4h/8h `no_summits`
differential-peak groups. Windows 50 and 51 are additionally summarized as the
center and compared with the raw total overlap-count change from 1m; this raw
count diagnostic is separate from the normalized persistence ratio.

### Retained RPKM workflow

For either scale, run the window, overlap, and RPKM jobs in that order. The
overlap jobs count real and simulated Damage-seq records in each window with
`bedtools intersect`. The shared Python script calculates:

`RPKM = overlap count x 10^9 / (total damage records x window length)`

The plotting notebooks contain separate sections for real RPKM, simulated
RPKM, and real/simulated profiles:

- `notebooks/damage profiles/differential_peak/no_summits_differential_damage_profiles_20kb.ipynb`
- `notebooks/damage profiles/differential_peak/no_summits_differential_damage_profiles_100kb.ipynb`

The `cpd_4h_8h_specific_comparison_100kb.ipynb` and
`64pp_1h_damage_4h_8h_specific_comparison_100kb.ipynb` notebooks compare the
100-kb damage profiles of the 4-hour- and 8-hour-specific regions.

`heterochromatin_overlap.slurm` is a separate descriptive analysis that reports
how many noUV-higher and UV-timepoint-higher regions overlap the H3K9me3 and
H3K27me3 reference BED files. It is not required for generating the damage
profiles.

## Data availability and paths

Large sequencing files, reference genomes, intermediate files, logs, and
generated results are not included. The SLURM files preserve the cluster paths
used during the project (`/cta/users/guneyn23`); these paths and Conda
environment names must be adapted before running the workflow elsewhere.
