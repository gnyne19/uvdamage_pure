
  library(ATACseqQC)

args <- commandArgs(trailingOnly = TRUE)



bamFile <- args[1]
sampleName <- args[2]
outPath <- args[3]



dir.create(outPath, recursive = TRUE, showWarnings = FALSE)



bam_qc <- ATACseqQC::bamQC(
  bamfile = bamFile,
  outPath = NULL,
)

print(bam_qc)

saveRDS(
  bam_qc,
  file = file.path(outPath, paste0(sampleName, ".bam_qc.rds"))
)

message("BAM QC finished: ", sampleName)
