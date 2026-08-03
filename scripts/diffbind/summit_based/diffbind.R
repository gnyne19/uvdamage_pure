library(DiffBind)


samples <- read.csv(
  "/cta/users/guneyn23/diffbind/diffbind_atac_samplesheet.csv"
)


db <- dba(sampleSheet = samples)
print(db)


db <- dba.count(
  db,
  summits = 250,                 
  filter = 1,
  bUseSummarizeOverlaps = TRUE,
  bParallel = FALSE
)

saveRDS(db, "diffbind_counted.rds")


pdf("diffbind_PCA.pdf")
dba.plotPCA(
  db,
  attributes = DBA_CONDITION,
  label = DBA_ID
)
dev.off()

pdf("diffbind_correlation_heatmap.pdf")
dba.plotHeatmap(db)
dev.off()



db <- dba.contrast(
  db,
  categories = DBA_CONDITION,
  minMembers = 2
)

cat("\n--- DIFFBIND CONTRASTS ---\n")
print(dba.show(db, bContrasts = TRUE))

saveRDS(db, "diffbind_with_contrasts.rds")
