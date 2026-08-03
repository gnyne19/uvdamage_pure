library(DiffBind)
library(BiocParallel)
library(rtracklayer)

analysis_dir <- "/cta/users/guneyn23/diffbind"
output_dir <- file.path(analysis_dir, "no_summits")
sample_sheet <- file.path(analysis_dir, "diffbind_atac_samplesheet.csv")
n_cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "5"))

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
register(MulticoreParam(workers = n_cores), default = TRUE)

samples <- read.csv(sample_sheet, stringsAsFactors = FALSE)
db <- dba(sampleSheet = samples)

cat("\n--- SAMPLES AND ORIGINAL PEAK SETS ---\n")
print(db)

db <- dba.count(
  db,
  summits = FALSE,
  filter = 1,
  bUseSummarizeOverlaps = TRUE,
  bParallel = TRUE
)

cat("\n--- FULL-WIDTH CONSENSUS PEAK MATRIX ---\n")
print(db)
saveRDS(db, file.path(output_dir, "no_summits_counted.rds"))

pdf(file.path(output_dir, "no_summits_count_PCA.pdf"))
dba.plotPCA(db, attributes = DBA_CONDITION, label = DBA_ID)
dev.off()

pdf(file.path(output_dir, "no_summits_count_heatmap.pdf"))
dba.plotHeatmap(db)
dev.off()

conditions <- unique(as.character(samples$Condition))
contrast_pairs <- combn(conditions, 2, simplify = FALSE)

for (pair in contrast_pairs) {
  group1 <- dba.mask(db, attribute = DBA_CONDITION, value = pair[1])
  group2 <- dba.mask(db, attribute = DBA_CONDITION, value = pair[2])

  db <- dba.contrast(
    db,
    design = FALSE,
    group1 = group1,
    group2 = group2,
    name1 = pair[1],
    name2 = pair[2],
    block = DBA_REPLICATE
  )
}

cat("\n--- ALL CONTRASTS ---\n")
print(dba.show(db, bContrasts = TRUE))
saveRDS(db, file.path(output_dir, "no_summits_with_contrasts.rds"))

db <- dba.analyze(
  db,
  method = DBA_DESEQ2,
  bParallel = FALSE
)

contrast_table <- as.data.frame(dba.show(db, bContrasts = TRUE))
print(contrast_table)

write.csv(
  contrast_table,
  file.path(output_dir, "no_summits_contrast_summary.csv"),
  row.names = FALSE
)

saveRDS(db, file.path(output_dir, "no_summits_analyzed_DESeq2.rds"))

pdf(file.path(output_dir, "no_summits_DESeq2_PCA.pdf"))
dba.plotPCA(
  db,
  attributes = DBA_CONDITION,
  label = DBA_ID,
  method = DBA_DESEQ2
)
dev.off()

pdf(file.path(output_dir, "no_summits_DESeq2_heatmap.pdf"))
dba.plotHeatmap(db, method = DBA_DESEQ2)
dev.off()

selected <- which(
  contrast_table$Group == "noUV" &
    contrast_table$DB.DESeq2 > 0
)

for (i in selected) {
  timepoint <- as.character(contrast_table$Group2[i])
  contrast_name <- paste("noUV", timepoint, sep = "_vs_")
  prefix <- paste("no_summits", contrast_name, "DESeq2", sep = "_")

  report <- dba.report(
    db,
    contrast = i,
    method = DBA_DESEQ2,
    th = 0.05
  )

  write.csv(
    as.data.frame(report),
    file.path(output_dir, paste0(prefix, "_report_FDR005.csv")),
    row.names = FALSE
  )

  noUV_higher <- report[mcols(report)$Fold > 0]
  timepoint_higher <- report[mcols(report)$Fold < 0]

  if (length(noUV_higher) > 0) {
    export(
      noUV_higher,
      file.path(output_dir, paste0(prefix, "_noUV_higher_FDR005.bed")),
      format = "BED"
    )
  }

  if (length(timepoint_higher) > 0) {
    export(
      timepoint_higher,
      file.path(
        output_dir,
        paste0(prefix, "_", timepoint, "_higher_FDR005.bed")
      ),
      format = "BED"
    )
  }

  pdf(file.path(output_dir, paste0(prefix, "_volcano.pdf")))
  dba.plotVolcano(db, contrast = i, method = DBA_DESEQ2, th = 0.05)
  dev.off()

  pdf(file.path(output_dir, paste0(prefix, "_MA.pdf")))
  dba.plotMA(db, contrast = i, method = DBA_DESEQ2, th = 0.05)
  dev.off()
}

cat("\nNo-summits analysis completed.\n")
