library(DiffBind)
library(rtracklayer)

result_dir <- "/cta/users/guneyn23/diffbind_nucleosome_free"
output_dir <- file.path(result_dir, "directional_results_DESeq2")
dir.create(output_dir, showWarnings = FALSE)

db <- readRDS(
  file.path(result_dir, "nucleosome_free_analyzed_all_methods.rds")
)

contrasts <- as.data.frame(dba.show(db, bContrasts = TRUE))

# Select noUV contrasts with significant DESeq2 sites.
selected <- which(
  contrasts$Group == "noUV" &
    contrasts$DB.DESeq2 > 0
)

write.csv(
  contrasts[selected, , drop = FALSE],
  file.path(output_dir, "nfr_selected_DESeq2_contrasts.csv"),
  row.names = FALSE
)

for (i in selected) {
  timepoint <- as.character(contrasts$Group2[i])
  contrast_name <- paste("noUV", timepoint, sep = "_vs_")

  report <- dba.report(
    db,
    contrast = i,
    method = DBA_DESEQ2,
    th = 0.05
  )

  fold <- mcols(report)$Fold
  noUV_specific <- report[fold > 0]
  timepoint_specific <- report[fold < 0]

  prefix <- paste("nucleosome_free", contrast_name, "DESeq2", sep = "_")

  write.csv(
    as.data.frame(report),
    file.path(output_dir, paste0(prefix, "_dba_report_FDR005.csv")),
    row.names = FALSE
  )

  export(
    noUV_specific,
    file.path(
      output_dir,
      paste0(prefix, "_noUV_specific_FDR005.bed")
    ),
    format = "BED"
  )

  export(
    timepoint_specific,
    file.path(
      output_dir,
      paste0(prefix, "_", timepoint, "_specific_FDR005.bed")
    ),
    format = "BED"
  )

  pdf(file.path(output_dir, paste0(prefix, "_volcano.pdf")))
  dba.plotVolcano(
    db,
    contrast = i,
    method = DBA_DESEQ2,
    th = 0.05
  )
  dev.off()

  pdf(file.path(output_dir, paste0(prefix, "_MA.pdf")))
  dba.plotMA(
    db,
    contrast = i,
    method = DBA_DESEQ2,
    th = 0.05
  )
  dev.off()
}
