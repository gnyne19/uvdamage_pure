# UV Damage and Chromatin Accessibility Analysis

This repository contains the analysis workflow developed during the Sabancı
University PURE Summer 2026 program. It combines ATAC-seq and Damage-seq to
study UV-induced DNA damage and repair across open and closed chromatin states.

## Final workflow

The canonical analysis proceeds in the following order:

1. **ATAC-seq processing and peak calling**
   - `slurms/atac_analysis_array/atac_array.slurm`
   - `slurms/atac_analysis_array/macs3_nucleosomefree_array.slurm`
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

## Data availability and paths

Large sequencing files, reference genomes, intermediate files, logs, and
generated results are not included. The SLURM files preserve the cluster paths
used during the project (`/cta/users/guneyn23`); these paths and Conda
environment names must be adapted before running the workflow elsewhere.
