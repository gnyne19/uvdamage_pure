library(ATACseqQC)
library(BSgenome.Hsapiens.UCSC.hg38)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(ChIPpeakAnno)
library(Rsamtools)

bamFile <- "/cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam"

outPath <- "/cta/users/guneyn23/bam_qc/split_shift_output"
dir.create(outPath)





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

print(tags)



gal <- readBamFile(
  bamFile,
  tag = tags,
 
  asMates = TRUE,
  bigFile = TRUE
)



shiftedBamFile <- file.path(outPath, "HelanoUV_R1_ATAC.shifted.bam")

gal1 <- shiftGAlignmentsList(
  gal,
  outbam = shiftedBamFile
)

txs = transcripts(TxDb.Hsapiens.UCSC.hg38.knownGene)


seqlevelsStyle(Hsapiens) <- "UCSC"
seqinfo(Hsapiens)
genome <- Hsapiens

objs <- splitGAlignmentsByCut(
  gal1,
  txs = txs,
  genome = genome,
  outPath = outPath
)

saveRDS(
  objs,
  file = file.path(outPath, "HelanoUV_R1_ATAC.split_shift.objs.rds")
)




