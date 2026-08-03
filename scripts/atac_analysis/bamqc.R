library(ATACseqQC)
library(BSgenome.Hsapiens.UCSC.hg38)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(ChIPpeakAnno)
library(Rsamtools)

bamFile <- "/cta/users/guneyn23/bam_filter2/HelanoUV_R1_ATAC.filtered.noMT.noBlacklist.bam"
bamFileLabels <- "HelanoUV_R1_ATAC"

bam_qc <- ATACseqQC::bamQC(
  bamfile = bamFile,
  outPath = NULL
)

print(bam_qc)

saveRDS(
  bam_qc,
  file = "/cta/users/guneyn23/bam_qc/HelanoUV_R1_ATAC.bam_qc.rds"
)