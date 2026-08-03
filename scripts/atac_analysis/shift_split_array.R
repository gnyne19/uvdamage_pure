
  library(ATACseqQC)
  library(BSgenome.Hsapiens.UCSC.hg38)
  library(TxDb.Hsapiens.UCSC.hg38.knownGene)
  library(ChIPpeakAnno)
  library(Rsamtools)

args <- commandArgs(trailingOnly = TRUE)


bamFile <- args[1]
sampleName <- args[2]
outPath <- args[3]



dir.create(outPath, recursive = TRUE, showWarnings = FALSE)


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
message("Found BAM tags: ", paste(tags, collapse = ", "))

gal <- readBamFile(
  bamFile,
  tag = tags,
  asMates = TRUE,
  bigFile = TRUE
)

shiftedBamFile <- file.path(outPath, paste0(sampleName, ".shifted.bam"))

galShifted <- shiftGAlignmentsList(
  gal,
  outbam = shiftedBamFile
)

txs <- transcripts(TxDb.Hsapiens.UCSC.hg38.knownGene)
seqlevelsStyle(txs) <- "UCSC"

Hsapiens <- BSgenome.Hsapiens.UCSC.hg38
seqlevelsStyle(Hsapiens) <- "UCSC"

objs <- splitGAlignmentsByCut(
  galShifted,
  txs = txs,
  genome = Hsapiens,
  outPath = outPath
)


rename_output <- function(oldName, newName) {
  oldPath <- file.path(outPath, oldName)
  newPath <- file.path(outPath, newName)

  if (!file.exists(oldPath)) {
    stop("Beklenen çıktı oluşturulmadı: ", oldPath)
  }

  if (file.exists(newPath)) {
    file.remove(newPath)
  }

  if (!file.rename(oldPath, newPath)) {
    stop("Dosya yeniden adlandırılamadı: ", oldPath, " -> ", newPath)
  }
}

rename_output(
  "NucleosomeFree.bam",
  paste0(sampleName, ".NucleosomeFree.bam")
)

saveRDS(
  objs,
  file = file.path(outPath, paste0(sampleName, ".split_shift.objs.rds"))
)

message("Shifted BAM created: ", shiftedBamFile)
message(
  "NFR BAM created: ",
  file.path(outPath, paste0(sampleName, ".NucleosomeFree.bam"))
)
message("Shift and split process completed.")
