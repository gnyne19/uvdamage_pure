
  library(ATACseqQC)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Usage: bamqc_array.R <bam_file> <sample_name> <output_dir>")
}


bamFile <- args[1]
sampleName <- args[2]
outPath <- args[3]

if (!file.exists(bamFile) || dir.exists(bamFile)) {
  stop("BAM input is missing or is not a file: ", bamFile)
}


dir.create(outPath, recursive = TRUE, showWarnings = FALSE)



bam_qc <- ATACseqQC::bamQC(
  bamfile = bamFile,
  outPath = NULL
)

print(bam_qc)

saveRDS(
  bam_qc,
  file = file.path(outPath, paste0(sampleName, ".bam_qc.rds"))
)

message("BAM QC finished: ", sampleName)
