# Run from ~/Documents/cftr_project after: source ~/start_session.sh

#!/bin/bash

# QUALITY CONTROL

# Create a directory for output from quality control (QC).
mkdir -p cftr_qc

# QC of the raw reads of boy and father.
SAMPLES=(
        "HG01500"
        "HG01502"
)

for SAMPLE in "${SAMPLES[@]}"; do

        fastqc ../shared_data/${SAMPLE}_R1.fastq.gz ../shared_data/${SAMPLE}_R2.fastq.gz -o cftr_qc

done

# TRIMMING

# Create a directory for the trimmed reads output.
mkdir -p cftr_trimmed

# Trim all four reads of boy and father.
SAMPLES=(
        "HG01500"
        "HG01502"
)

for SAMPLE in "${SAMPLES[@]}"; do
# Input: ${SAMPLE}_R1.fastq.gz and ${SAMPLE}_R2.fastq.gz
# Output: cftr_trimmed/${SAMPLE}_R1.fastq.gz and cftr_trimmed/${SAMPLE}_R2.fastq.gz
# Generate an HTML report for each sample in cftr_trimmed/
         fastp \
                  -i "../shared_data/${SAMPLE}_R1.fastq.gz" \
                  -I "../shared_data/${SAMPLE}_R2.fastq.gz" \
                  -o "cftr_trimmed/${SAMPLE}_R1.fastq.gz" \
                  -O "cftr_trimmed/${SAMPLE}_R2.fastq.gz" \
                  --html "cftr_trimmed/${SAMPLE}_fastp.html"\
                 --json "cftr_trimmed/${SAMPLE}_fastp.json"
                  
done

# ALIGNMENT

# Create a directory for output alignment files.
mkdir -p cftr_mapped

# Align boy and father trimmed reads against reference genome GRCh38 (chromosome 7, chr7), adding read groups for GATK.
SAMPLES=(
        "HG01502"
        "HG01500"
)

for SAMPLE in "${SAMPLES[@]}"; do
# Alignment (bwa mem) + read groups (-R) + conversion of SAM to BAM in one command.
                bwa mem -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tLB:${SAMPLE}\tPL:ILLUMINA"\
                /tmp/ref/chr7.fa cftr_trimmed/${SAMPLE}_R1.fastq.gz\
                cftr_trimmed/${SAMPLE}_R2.fastq.gz | samtools view -b -o cftr_mapped/${SAMPLE}_aligned.bam

done

# SORTING READS AND MARKING DUPLICATES

# Activation of GATK command: FOR ALL GATK PIPELINE STEPS FROM SORTING TO SITE-LEVEL FILTERING.

# Use GATK (with its own Java) from /tmp/gatk_env inside this script.
export PATH=/tmp/gatk_env/bin:$PATH

# Create directories for sorting, marking duplicates and indexing output.
mkdir -p cftr_sorted
mkdir -p cftr_marked

# Create a list of samples.
SAMPLES=(
        "HG01500"
        "HG01502"
)

# Loop for sorting duplicates for boy and father reads.
for SAMPLE in "${SAMPLES[@]}"; do
                gatk SortSam -I cftr_mapped/${SAMPLE}_aligned.bam -O cftr_sorted/${SAMPLE}_sorted.bam -SORT_ORDER coordinate
                gatk MarkDuplicates -I cftr_sorted/${SAMPLE}_sorted.bam -O cftr_marked/${SAMPLE}_marked.bam -M cftr_marked/${SAMPLE}_metrics.txt
                gatk BuildBamIndex -I cftr_marked/${SAMPLE}_marked.bam -O cftr_marked/${SAMPLE}_marked.bam.bai

done

# BASE QUALITY SCORE RECALIBRATION

# Create a directory for Base Quality Score Recalibration output.
mkdir -p cftr_BQSR

# Base quality score recalibration for boy and father reads.
SAMPLES=(
        "HG01500"
        "HG01502"
)

for SAMPLE in "${SAMPLES[@]}"; do
                gatk BaseRecalibrator -I cftr_marked/${SAMPLE}_marked.bam -R /tmp/ref/chr7.fa --known-sites /tmp/ref/known_indels_chr7.vcf.gz  -O cftr_BQSR/${SAMPLE}_recal.table
                gatk ApplyBQSR -I cftr_marked/${SAMPLE}_marked.bam -R /tmp/ref/chr7.fa --bqsr-recal-file cftr_BQSR/${SAMPLE}_recal.table -O cftr_BQSR/${SAMPLE}_recal.bam

done

# VARIANT CALLING

# Create a directory for variant calling output for boy and father samples.
mkdir -p cftr_VCF

# Call variants for boy and father samples.
SAMPLES=(
        "HG01500"
        "HG01502"
)

# -L restricts calling to the extracted CFTR region (without it, the run fails with an out-of-memory error).
for SAMPLE in "${SAMPLES[@]}"; do
                gatk HaplotypeCaller -I cftr_BQSR/${SAMPLE}_recal.bam -R /tmp/ref/chr7.fa -O cftr_VCF/${SAMPLE}.g.vcf.gz -ERC GVCF -L chr7:117400000-117750000
done

# COMBINE GENOTYPES AND JOINT GENOTYPING

# 1. Combine GVCFs of the boy and father into one multi-sample GVCF file.

gatk CombineGVCFs \
    -R /tmp/ref/chr7.fa \
    -V cftr_VCF/HG01502.g.vcf.gz \
    -V cftr_VCF/HG01500.g.vcf.gz \
    -O cftr_VCF/family.g.vcf.gz \
    -L chr7:117400000-117750000

# 2. Joint genotyping: genotype boy and father together, so that each variant site has a genotype for both of them.
# 0/0 for the father means "checked: no variant", ./. means "no data".
# Genotyping output allows the inheritance comparison.
gatk GenotypeGVCFs \
    -R /tmp/ref/chr7.fa \
    -V cftr_VCF/family.g.vcf.gz \
    -O cftr_VCF/family.vcf.gz \
    -L chr7:117400000-117750000

# FILTERING

# 1. Site-level hard filters (GATK standard).
# Flag variant positions that do not pass the GATK quality control.
gatk VariantFiltration \
    -R /tmp/ref/chr7.fa \
    -V cftr_VCF/family.vcf.gz \
    -O cftr_VCF/family.filtered.vcf.gz \
    --filter-name "QD2"    --filter-expression "QD < 2.0" \
    --filter-name "QUAL30" --filter-expression "QUAL < 30.0" \
    --filter-name "FS60"   --filter-expression "FS > 60.0" \
    --filter-name "MQ40"   --filter-expression "MQ < 40.0"

# 2. Genotype-level allele-balance filter (checked for each person separately).
# A heterozygous call supported by less than 20% of that person's reads is set to missing (./.).
bcftools filter -S . -e 'GT="het" & FMT/AD[:1]/FMT/DP < 0.2' \
    cftr_VCF/family.filtered.vcf.gz -Oz -o cftr_VCF/family.filtered_ab.vcf.gz

# 3. Keep only sites that passed the site-level filters.
bcftools view -f PASS cftr_VCF/family.filtered_ab.vcf.gz -Oz -o cftr_VCF/family.pass.vcf.gz
bcftools index -t cftr_VCF/family.pass.vcf.gz

# 4. Keep only variants inside the CFTR gene (GRCh38, NCBI Gene ID 1080).
bcftools view -r chr7:117480025-117668665 cftr_VCF/family.pass.vcf.gz -Oz -o cftr_VCF/family.CFTR.vcf.gz
bcftools index -t cftr_VCF/family.CFTR.vcf.gz

# 5. Table of genotypes for the father-son comparison (columns: POS, REF, ALT, father, boy).
bcftools query -f '%POS\t%REF\t%ALT\t[%GT\t]\n' cftr_VCF/family.CFTR.vcf.gz > cftr_genotypes.tsv
