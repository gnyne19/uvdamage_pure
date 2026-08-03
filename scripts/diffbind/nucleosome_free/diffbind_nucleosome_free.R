library(DiffBind)
library(BiocParallel)

analysis_dir <- "/cta/users/guneyn23/diffbind_nucleosome_free"
sample_sheet <- file.path(analysis_dir, "samplesheet_nucleosome_free.csv")
n_cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = "5"))
options(mc.cores = n_cores, cores = n_cores)
register(MulticoreParam(workers = n_cores), default = TRUE)

samples <- read.csv(sample_sheet, stringsAsFactors = FALSE)



db <- dba(sampleSheet = samples)
print(db)

db <- dba.count(
  db,
  summits = 75,
  filter = 1,
  bUseSummarizeOverlaps = TRUE,
  bParallel = TRUE
)

print(db)
saveRDS(db, file.path(analysis_dir, "nucleosome_free_counted.rds"))

pdf(file.path(analysis_dir, "nucleosome_free_PCA_condition.pdf"))
dba.plotPCA(db, attributes = DBA_CONDITION, label = DBA_ID)
dev.off()



pdf(file.path(analysis_dir, "nucleosome_free_correlation_heatmap.pdf"))
dba.plotHeatmap(db)
dev.off()

conditions <- unique(as.character(samples$Condition))
contrast_pairs <- combn(conditions, 2, simplify = FALSE)

for (pair in contrast_pairs) {
  group1_mask <- dba.mask(
    db,
    attribute = DBA_CONDITION,
    value = pair[1]
  )
  group2_mask <- dba.mask(
    db,
    attribute = DBA_CONDITION,
    value = pair[2]
  )

  db <- dba.contrast(
    db,
    design = FALSE,
    group1 = group1_mask,
    group2 = group2_mask,
    name1 = pair[1],
    name2 = pair[2],
    block = DBA_REPLICATE
  )
}

cat("\n--- NUCLEOSOME-FREE CONTRASTS ---\n")
print(dba.show(db, bDesign = TRUE))
print(dba.show(db, bContrasts = TRUE))

saveRDS(db, file.path(analysis_dir, "nucleosome_free_with_contrasts.rds"))

cat("\n--- DESEQ2 AND EDGER NORMALIZATION AND ANALYSIS ---\n")
db <- dba.analyze(
  db,
  method = DBA_ALL_METHODS,
  bParallel = FALSE
)

print(dba.show(db, bContrasts = TRUE))
saveRDS(db, file.path(analysis_dir, "nucleosome_free_analyzed_all_methods.rds"))

pdf(file.path(analysis_dir, "nucleosome_free_PCA_after_analysis_DESeq2.pdf"))
dba.plotPCA(db, attributes = DBA_CONDITION, label = DBA_ID, method = DBA_DESEQ2)
dev.off()

pdf(file.path(analysis_dir, "nucleosome_free_PCA_after_analysis_edgeR.pdf"))
dba.plotPCA(db, attributes = DBA_CONDITION, label = DBA_ID, method = DBA_EDGER)
dev.off()

pdf(file.path(analysis_dir, "nucleosome_free_heatmap_after_analysis_DESeq2.pdf"))
dba.plotHeatmap(db, method = DBA_DESEQ2)
dev.off()

pdf(file.path(analysis_dir, "nucleosome_free_heatmap_after_analysis_edgeR.pdf"))
dba.plotHeatmap(db, method = DBA_EDGER)
dev.off()

noUV_contrasts <- which(vapply(
  contrast_pairs,
  function(pair) "noUV" %in% pair,
  logical(1)
))

for (contrast_index in noUV_contrasts) {
  pair <- contrast_pairs[[contrast_index]]
  contrast_name <- paste(pair, collapse = "_vs_")

  report_deseq2 <- dba.report(
    db,
    contrast = contrast_index,
    method = DBA_DESEQ2,
    th = 0.05
  )
  write.csv(
    as.data.frame(report_deseq2),
    file.path(
      analysis_dir,
      paste0("nucleosome_free_report_", contrast_name, "_DESeq2_FDR005.csv")
    ),
    row.names = FALSE
  )
  deseq2_bed <- file.path(
    analysis_dir,
    paste0(
      "nucleosome_free_differential_",
      contrast_name,
      "_DESeq2_FDR005.bed"
    )
  )
  if (is.null(report_deseq2) || length(report_deseq2) == 0) {
    file.create(deseq2_bed)
  } else {
    rtracklayer::export(report_deseq2, deseq2_bed, format = "BED")
  }

  report_edger <- dba.report(
    db,
    contrast = contrast_index,
    method = DBA_EDGER,
    th = 0.05
  )
  write.csv(
    as.data.frame(report_edger),
    file.path(
      analysis_dir,
      paste0("nucleosome_free_report_", contrast_name, "_edgeR_FDR005.csv")
    ),
    row.names = FALSE
  )
  edger_bed <- file.path(
    analysis_dir,
    paste0(
      "nucleosome_free_differential_",
      contrast_name,
      "_edgeR_FDR005.bed"
    )
  )
  if (is.null(report_edger) || length(report_edger) == 0) {
    file.create(edger_bed)
  } else {
    rtracklayer::export(report_edger, edger_bed, format = "BED")
  }

  pdf(file.path(
    analysis_dir,
    paste0("nucleosome_free_volcano_", contrast_name, "_DESeq2.pdf")
  ))
  dba.plotVolcano(db, contrast = contrast_index, method = DBA_DESEQ2)
  dev.off()

  pdf(file.path(
    analysis_dir,
    paste0("nucleosome_free_volcano_", contrast_name, "_edgeR.pdf")
  ))
  dba.plotVolcano(db, contrast = contrast_index, method = DBA_EDGER)
  dev.off()

  pdf(file.path(
    analysis_dir,
    paste0("nucleosome_free_MA_", contrast_name, "_DESeq2.pdf")
  ))
  dba.plotMA(db, contrast = contrast_index, method = DBA_DESEQ2)
  dev.off()

  pdf(file.path(
    analysis_dir,
    paste0("nucleosome_free_MA_", contrast_name, "_edgeR.pdf")
  ))
  dba.plotMA(db, contrast = contrast_index, method = DBA_EDGER)
  dev.off()
}
