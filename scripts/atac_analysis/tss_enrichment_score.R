library(ATACseqQC)
library(BSgenome.Hsapiens.UCSC.hg38)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(ChIPpeakAnno)
library(Rsamtools)

bamFile <- "/cta/users/guneyn23/bam_qc/split_shift_output/HelanoUV_R1_ATAC.shifted.bam"

txs = transcripts(TxDb.Hsapiens.UCSC.hg38.knownGene)

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
  bigFile = FALSE
)





tsse <- TSSEscore(gal, txs)
tsse$TSSEscore
print(tsse$TSSEscore)

plot(
  100 * (-9:10 - 0.5),
  tsse$values,
  type = "b",
  xlab = "Distance to TSS (bp)",
  ylab = "Aggregate TSS score"
)