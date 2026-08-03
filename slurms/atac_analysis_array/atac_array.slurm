#!/bin/bash

#SBATCH --account=users
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --qos=long_mdbf
#SBATCH --partition=long_mdbf
#SBATCH --job-name=atac_pipeline
#SBATCH --array=0-12
#SBATCH --output=/cta/users/guneyn23/atac_pipeline_logs/atac_%A_%a.out
#SBATCH --error=/cta/users/guneyn23/atac_pipeline_logs/atac_%A_%a.err
#SBATCH --mem=256G



set -euo pipefail

echo "Job Started"
echo "Array job ID: ${SLURM_ARRAY_JOB_ID}"
echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
date



source /cta/users/guneyn23/miniconda3/etc/profile.d/conda.sh

# Fail before the long preprocessing steps if the ATACseqQC installation is
# incomplete or corrupted.
conda activate atacseqqc
Rscript -e 'library(ATACseqQC); library(TxDb.Hsapiens.UCSC.hg38.knownGene); library(BSgenome.Hsapiens.UCSC.hg38)'
command -v bamCoverage >/dev/null

conda deactivate
conda activate atacseq





SAMPLES=(
    "Hela_1h_R1_ATAC"
    "Hela_1h_R3_ATAC"
    "Hela_1m_R1_ATAC"
    "Hela_1m_R3_ATAC"
    "Hela_4h_R1_ATAC"
    "Hela_4h_R3_ATAC"
    "Hela_8h_R1_ATAC"
    "Hela_8h_R3_ATAC"
    "Hela_15m_R1_ATAC"
    "Hela_15m_R3_ATAC"
    "Hela_30m_R1_ATAC"
    "Hela_30m_R3_ATAC"
    "HelanoUV_R3_ATAC"
)

R1_FILES=(
    "/cta/users/guneyn23/atacdata/Hela_1h_R1_ATAC_combined26_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_1h_R3_ATAC_combined26_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_1m_R1_ATAC_combined26_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_1m_R3_ATAC_AGGCAGAA-CTCTCTAT_S3_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_4h_R1_ATAC_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_4h_R3_ATAC_TCCTGAGC-CTCTCTAT_S4_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_8h_R1_ATAC_CGTACTAG-TATCCTCT_S5_combined26_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_8h_R3_ATAC_TCCTGAGC-TATCCTCT_S6_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_15m_R1_ATAC_TAAGGCGA-TATCCTCT_S1_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_15m_R3_ATAC_AGGCAGAA-TATCCTCT_S2_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_30m_R1_ATAC_combined26_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_30m_R3_ATAC_combined26_1.fastq.gz"
    "/cta/users/guneyn23/atacdata/HelanoUV_R3_ATAC_combined26_1.fastq.gz"
)

R2_FILES=(
    "/cta/users/guneyn23/atacdata/Hela_1h_R1_ATAC_combined26_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_1h_R3_ATAC_combined26_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_1m_R1_ATAC_combined26_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_1m_R3_ATAC_AGGCAGAA-CTCTCTAT_S3_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_4h_R1_ATAC_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_4h_R3_ATAC_TCCTGAGC-CTCTCTAT_S4_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_8h_R1_ATAC_CGTACTAG-TATCCTCT_S5_combined26_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_8h_R3_ATAC_TCCTGAGC-TATCCTCT_S6_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_15m_R1_ATAC_TAAGGCGA-TATCCTCT_S1_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_15m_R3_ATAC_AGGCAGAA-TATCCTCT_S2_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_30m_R1_ATAC_combined26_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/Hela_30m_R3_ATAC_combined26_2.fastq.gz"
    "/cta/users/guneyn23/atacdata/HelanoUV_R3_ATAC_combined26_2.fastq.gz"
)

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"
R1="${R1_FILES[$SLURM_ARRAY_TASK_ID]}"
R2="${R2_FILES[$SLURM_ARRAY_TASK_ID]}"



echo "current sample: $SAMPLE"
echo "R1: $R1"
echo "R2: $R2"



BASE_DIR="/cta/users/guneyn23/atacseq_results"

BOWTIE2_INDEX="/cta/users/guneyn23/reference_genome/bowtie2_index/genome_hg38"

BLACKLIST="/cta/users/guneyn23/reference_genome/ENCFF356LFX.bed"
SAMPLE_DIR="${BASE_DIR}/${SAMPLE}"


RAW_FASTQC_DIR="${SAMPLE_DIR}/01_fastqc_raw"
TRIM_DIR="${SAMPLE_DIR}/02_trimmed_fastq"
FASTP_REPORT_DIR="${SAMPLE_DIR}/03_fastp_reports"
TRIM_FASTQC_DIR="${SAMPLE_DIR}/04_fastqc_trimmed"
ALIGN_DIR="${SAMPLE_DIR}/05_alignment"
FILTER_DIR="${SAMPLE_DIR}/06_bam_filter"
FINAL_BAM_DIR="${SAMPLE_DIR}/07_final_bam"
QC_DIR="${SAMPLE_DIR}/08_qc"
BAMQC_DIR="${SAMPLE_DIR}/09_bamqc"
SHIFT_DIR="${SAMPLE_DIR}/10_shift_split"
TSS_DIR="${SAMPLE_DIR}/11_tss_enrichment"
BIGWIG_DIR="${SAMPLE_DIR}/12_bigwig"
PEAK_DIR="${SAMPLE_DIR}/13_macs3_peaks"


mkdir -p \
    "$RAW_FASTQC_DIR" \
    "$TRIM_DIR" \
    "$FASTP_REPORT_DIR" \
    "$TRIM_FASTQC_DIR" \
    "$ALIGN_DIR" \
    "$FILTER_DIR" \
    "$FINAL_BAM_DIR" \
    "$QC_DIR" \
    "$BAMQC_DIR" \
    "$SHIFT_DIR" \
    "$TSS_DIR" \
    "$BIGWIG_DIR" \
    "$PEAK_DIR"


TRIM_R1="${TRIM_DIR}/${SAMPLE}_R1.trimmed.fastq.gz"
TRIM_R2="${TRIM_DIR}/${SAMPLE}_R2.trimmed.fastq.gz"

SAM="${ALIGN_DIR}/${SAMPLE}.sam"
UNSORTED_BAM="${ALIGN_DIR}/${SAMPLE}.bam"
SORTED_BAM="${ALIGN_DIR}/${SAMPLE}.sorted.bam"

NAME_SORTED_BAM="${FILTER_DIR}/${SAMPLE}.namesorted.bam"
FIXMATE_BAM="${FILTER_DIR}/${SAMPLE}.fixmate.bam"
FIXMATE_SORTED_BAM="${FILTER_DIR}/${SAMPLE}.fixmate.sorted.bam"
MARKDUP_BAM="${FILTER_DIR}/${SAMPLE}.markdup.bam"
FILTERED_BAM="${FILTER_DIR}/${SAMPLE}.filtered.bam"

FINAL_BAM="${FINAL_BAM_DIR}/${SAMPLE}.filtered.noMT.noBlacklist.bam"




echo ""
echo "1/14 — Raw FASTQ FastQC started"
date

fastqc \
    -t "$SLURM_CPUS_PER_TASK" \
    -o "$RAW_FASTQC_DIR" \
    "$R1" \
    "$R2"

echo "Raw FastQC finished."




echo ""
echo "2/14 — fastp started"
date

fastp \
    -i "$R1" \
    -I "$R2" \
    -o "$TRIM_R1" \
    -O "$TRIM_R2" \
    --adapter_sequence CTGTCTCTTATACACATCT \
    --adapter_sequence_r2 CTGTCTCTTATACACATCT \
    --qualified_quality_phred 20 \
    --dedup \
    --thread "$SLURM_CPUS_PER_TASK" \
    --html "${FASTP_REPORT_DIR}/${SAMPLE}_fastp.html" \
    --json "${FASTP_REPORT_DIR}/${SAMPLE}_fastp.json"

echo "fastp finished."





echo ""
echo "3/14 — Trimmed FASTQ FastQC started"
date

fastqc \
    -t "$SLURM_CPUS_PER_TASK" \
    -o "$TRIM_FASTQC_DIR" \
    "$TRIM_R1" \
    "$TRIM_R2"

echo "Trimmed FastQC finished."




echo ""
echo "4/14 — Bowtie2 alignment started"
date

bowtie2 \
    -p "$SLURM_CPUS_PER_TASK" \
    -x "$BOWTIE2_INDEX" \
    --local \
    --very-sensitive \
    --no-mixed \
    --no-discordant \
    -I 25 \
    -X 700 \
    --seed 42 \
    -1 "$TRIM_R1" \
    -2 "$TRIM_R2" \
    -S "$SAM" \
    2> "${ALIGN_DIR}/${SAMPLE}_bowtie2.log"

echo "Bowtie2 alignment finished."




echo ""
echo "5/14 — SAM to BAM started"
date

samtools view \
    -@ "$SLURM_CPUS_PER_TASK" \
    -bS "$SAM" \
    -o "$UNSORTED_BAM"

samtools sort \
    -@ "$SLURM_CPUS_PER_TASK" \
    -o "$SORTED_BAM" \
    "$UNSORTED_BAM"

samtools index \
    -@ "$SLURM_CPUS_PER_TASK" \
    "$SORTED_BAM"

samtools flagstat \
    "$SORTED_BAM" \
    > "${QC_DIR}/${SAMPLE}.sorted.flagstat.txt"

samtools idxstats \
    "$SORTED_BAM" \
    > "${QC_DIR}/${SAMPLE}.sorted.idxstats.txt"

echo "SAM to BAM finished."



echo ""
echo "6/14 — Duplicate marking started"
date



samtools sort \
    -@ "$SLURM_CPUS_PER_TASK" \
    -n \
    -o "$NAME_SORTED_BAM" \
    "$SORTED_BAM"

samtools fixmate \
    -@ "$SLURM_CPUS_PER_TASK" \
    -m \
    "$NAME_SORTED_BAM" \
    "$FIXMATE_BAM"

samtools sort \
    -@ "$SLURM_CPUS_PER_TASK" \
    -o "$FIXMATE_SORTED_BAM" \
    "$FIXMATE_BAM"

samtools markdup \
    -@ "$SLURM_CPUS_PER_TASK" \
    -s \
    "$FIXMATE_SORTED_BAM" \
    "$MARKDUP_BAM" \
    2> "${QC_DIR}/${SAMPLE}.markdup.stats.txt"

echo "Duplicate marking finished."



echo ""
echo "7/14 — BAM filtering started"
date


samtools view \
    -@ "$SLURM_CPUS_PER_TASK" \
    -b \
    -f 2 \
    -F 1548 \
    -q 30 \
    "$MARKDUP_BAM" \
    > "$FILTERED_BAM"

samtools index \
    -@ "$SLURM_CPUS_PER_TASK" \
    "$FILTERED_BAM"

samtools flagstat \
    "$FILTERED_BAM" \
    > "${QC_DIR}/${SAMPLE}.filtered.flagstat.txt"

samtools idxstats \
    "$FILTERED_BAM" \
    > "${QC_DIR}/${SAMPLE}.filtered.idxstats.txt"

echo "Temel BAM filtering finished."


echo ""
echo "8/14 — Mitokondri and blacklist filtering started"
date

CHROMS_TO_KEEP="$(
    samtools idxstats "$FILTERED_BAM" |
    cut -f1 |
    grep -v -E '^chrM$|^MT$|^\*$'
)"

samtools view \
    -@ "$SLURM_CPUS_PER_TASK" \
    -b \
    "$FILTERED_BAM" \
    $CHROMS_TO_KEEP |
bedtools intersect \
    -v \
    -abam - \
    -b "$BLACKLIST" \
    > "$FINAL_BAM"

samtools index \
    -@ "$SLURM_CPUS_PER_TASK" \
    "$FINAL_BAM"

samtools flagstat \
    "$FINAL_BAM" \
    > "${QC_DIR}/${SAMPLE}.final.flagstat.txt"

samtools idxstats \
    "$FINAL_BAM" \
    > "${QC_DIR}/${SAMPLE}.final.idxstats.txt"

echo "Mitokondri ve blacklist filtering finished"



echo ""
echo "9/14 — Fragment length analysis started"
date

conda deactivate
conda activate atacseq

picard CollectInsertSizeMetrics \
    I="$FINAL_BAM" \
    O="${QC_DIR}/${SAMPLE}.fraglen.stats.txt" \
    H="${QC_DIR}/${SAMPLE}.fraglen.pdf" \
    M=0.5

if [[ ! -s "${QC_DIR}/${SAMPLE}.fraglen.stats.txt" ]]; then
    echo "HATA: Fragment length istatistik dosyası oluşturulamadı."
    exit 1
fi

echo "Fragment length analysis finished."


echo ""
echo "10/14 — ATACseqQC bamQC analysis started"
date

conda deactivate
conda activate atacseqqc

Rscript /cta/users/guneyn23/bam_qc/tss_array.R \
    "$FINAL_BAM" \
    "$SAMPLE" \
    "$BAMQC_DIR"

if [[ ! -s "${BAMQC_DIR}/${SAMPLE}.bam_qc.rds" ]]; then
    echo "HATA: bamQC RDS dosyası oluşturulamadı:"
    echo "${BAMQC_DIR}/${SAMPLE}.bam_qc.rds"
    exit 1
fi

echo "ATACseqQC bamQC analysis finished."


echo ""
echo "11/14 — Tn5 shift ve fragment split started"
date

Rscript /cta/users/guneyn23/bam_qc/shift_split_array.R \
    "$FINAL_BAM" \
    "$SAMPLE" \
    "$SHIFT_DIR"

SHIFTED_BAM="${SHIFT_DIR}/${SAMPLE}.shifted.bam"
NFR_BAM="${SHIFT_DIR}/${SAMPLE}.NucleosomeFree.bam"

if [[ ! -s "$SHIFTED_BAM" ]]; then
    echo "HATA: Shifted BAM oluşturulamadı veya dosya boş:"
    echo "$SHIFTED_BAM"
    exit 1
fi

if [[ ! -s "$NFR_BAM" ]]; then
    echo "HATA: Nucleosome-free BAM oluşturulamadı veya dosya boş:"
    echo "$NFR_BAM"
    exit 1
fi

samtools index \
    -@ "$SLURM_CPUS_PER_TASK" \
    "$SHIFTED_BAM"

samtools index \
    -@ "$SLURM_CPUS_PER_TASK" \
    "$NFR_BAM"

echo "Tn5 shift ve fragment split finished."


echo ""
echo "12/14 — TSS enrichment analysis started"
date

Rscript /cta/users/guneyn23/tss_enrichment_score/tss_enrichment_score_array.R \
    "$SHIFTED_BAM" \
    "$SAMPLE" \
    "$TSS_DIR"

if [[ ! -s "${TSS_DIR}/${SAMPLE}.TSS_enrichment_score.tsv" ]]; then
    echo "HATA: TSS enrichment skor dosyası oluşturulamadı:"
    echo "${TSS_DIR}/${SAMPLE}.TSS_enrichment_score.tsv"
    exit 1
fi

echo "TSS enrichment analysis finished."


echo ""
echo "13/14 — Bam to BigWig started"
date

conda deactivate
conda activate atacseqqc

# Tüm shifted ATAC-seq sinyali
bamCoverage \
    --bam "$SHIFTED_BAM" \
    --outFileName "${BIGWIG_DIR}/${SAMPLE}.shifted.RPGC.bw" \
    --binSize 10 \
    --normalizeUsing RPGC \
    --effectiveGenomeSize 2701495711 \
    --numberOfProcessors "$SLURM_CPUS_PER_TASK"

# Yalnızca nucleosome-free fragment sinyali
bamCoverage \
    --bam "$NFR_BAM" \
    --outFileName "${BIGWIG_DIR}/${SAMPLE}.NucleosomeFree.RPGC.bw" \
    --binSize 10 \
    --normalizeUsing RPGC \
    --effectiveGenomeSize 2701495711 \
    --numberOfProcessors "$SLURM_CPUS_PER_TASK"

if [[ ! -s "${BIGWIG_DIR}/${SAMPLE}.shifted.RPGC.bw" ]]; then
    echo "HATA: Shifted BigWig oluşturulamadı."
    exit 1
fi

if [[ ! -s "${BIGWIG_DIR}/${SAMPLE}.NucleosomeFree.RPGC.bw" ]]; then
    echo "HATA: Nucleosome-free BigWig oluşturulamadı."
    exit 1
fi

echo "Bam to BigWig finished."


echo ""
echo "14/14 — MACS3 peak calling started"
date

conda deactivate
conda activate macs3

macs3 callpeak \
    -t "$FINAL_BAM" \
    -f BAMPE \
    -g hs \
    -n "$SAMPLE" \
    -B \
    -q 0.01 \
    --outdir "$PEAK_DIR"

if [[ ! -s "${PEAK_DIR}/${SAMPLE}_peaks.narrowPeak" ]]; then
    echo "HATA: MACS3 narrowPeak dosyası oluşturulamadı."
    exit 1
fi

echo "MACS3 peak calling finished."


echo ""
echo "Irrelevant files are removing."

rm -f \
    "$SAM" \
    "$UNSORTED_BAM" \
    "$NAME_SORTED_BAM" \
    "$FIXMATE_BAM" \
    "$FIXMATE_SORTED_BAM"


echo "Job completed: $SAMPLE"
date
