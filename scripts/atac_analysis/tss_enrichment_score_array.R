
  library(ATACseqQC)
  library(TxDb.Hsapiens.UCSC.hg38.knownGene)
  library(ChIPpeakAnno)
  library(Rsamtools)
  library(GenomeInfoDb)


args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Usage: tss_enrichment_score_array.R <bam_file> <sample_name> <output_dir>")
}


bamFile <- args[1]
sampleName <- args[2]
outPath <- args[3]

if (!file.exists(bamFile) || dir.exists(bamFile)) {
  stop("BAM input is missing or is not a file: ", bamFile)
}

dir.create(outPath, recursive = TRUE, showWarnings = FALSE)

message("TSS enrichment analysis started: ", sampleName)

txs <- transcripts(TxDb.Hsapiens.UCSC.hg38.knownGene)
seqlevelsStyle(txs) <- "UCSC"

possibleTag <- combn(LETTERS, 2)
possibleTag <- c(
  paste0(possibleTag[1, ], possibleTag[2, ]),
  paste0(possibleTag[2, ], possibleTag[1, ])
)

bamTop100 <- scanBam(
  BamFile(bamFile, yieldSize = 100),
  param = ScanBamParam(tag = possibleTag)
)[[1]]$tag

tags <- names(bamTop100)[lengths(bamTop100) > 0]

gal <- readBamFile(
  bamFile,
  tag = tags,
  asMates = FALSE,
  bigFile = TRUE
)

tsse <- TSSEscore(gal, txs)
score <- tsse$TSSEscore

message("TSS enrichment score: ", score)

write.table(
  data.frame(sample = sampleName, TSS_enrichment_score = score),
  file = file.path(outPath, paste0(sampleName, ".TSS_enrichment_score.tsv")),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

saveRDS(
  tsse,
  file = file.path(outPath, paste0(sampleName, ".TSSEscore.rds"))
)

pdf(
  file.path(outPath, paste0(sampleName, ".TSS_enrichment_profile.pdf")),
  width = 7,
  height = 5
)
plot(
  100 * (-9:10 - 0.5),
  tsse$values,
  type = "b",
  xlab = "Distance to TSS (bp)",
  ylab = "Aggregate TSS score",
  main = paste(sampleName, "TSS enrichment")
)
abline(h = 1, lty = 2)
dev.off()
