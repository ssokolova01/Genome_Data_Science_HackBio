#!/bin/bash

# 1. Quality Control (QC).
# Create `qc` directory for QC output files.
mkdir -p qc
# QC analysis for both reads in one command.
fastqc ~/Documents/shared_data/NA12878_R1.fastq.gz ~/Documents/shared_data/NA12878_R2.fastq.gz -o qc/GATK_training/

# 2. Trimming.
# Create `GATK_trimmed` directory for trimming output files.
mkdir -p GATK_trimmed

# Create a sample list (there is one sample name in this analysis).
SAMPLES=(
      "NA12878"
)

# Bash script to iterate over the samples and run fastp for paired-end reads.

for SAMPLE in "${SAMPLES[@]}"; do
# Input: ../../shared_data/${SAMPLE}_R1.fastq.gz and ../../shared_data/${SAMPLE}_R2.fastq.gz
# Output: ../../GATK_trimmed/${SAMPLE}_R1.fastq.gz and ../../GATK_trimmed/${SAMPLE}_R2.fastq.gz
# Generate an HTML report for each sample in qc_reads/
         fastp \
                  -i "../shared_data/${SAMPLE}_R1.fastq.gz" \
                  -I "../shared_data/${SAMPLE}_R2.fastq.gz" \
                  -o "GATK_trimmed/${SAMPLE}_R1.fastq.gz" \
                  -O "GATK_trimmed/${SAMPLE}_R2.fastq.gz" \
                  --html "GATK_trimmed/${SAMPLE}_fastp.html"
                  
done

# 3. Alignment.
# Create `map` directory for alignment output files.
mkdir -p map

# Alignment,.sam files compressing and saving output file in prepared directory in one command.
bwa mem -R '@RG\tID:NA12878\tSM:NA12878\tPL:ILLUMINA' /tmp/ref/chr7.fa GATK_trimmed/NA12878_R1.fastq.gz GATK_trimmed/NA12878_R2.fastq.gz | samtools view -b -o map/NA12878_aligned.bam

# Check created .bam files.
samtools view NA12878_aligned.bam | head -n 5

# 4. Sorting and MArking Duplicates.
# Create `sorted` and `marked` directories for sorted and marked output.
mkdir -p sorted 
mkdir -p marked

# Sorting reads and saving output file in prepared directory.
gatk SortSam -I map/NA12878_aligned.bam -O sorted/NA12878_sorted.bam

# Marking duplicates and save the output files in prepared directories.
gatk MarkDuplicates -I sorted/NA12878_sorted.bam -O marked/NA12878_marked.bam -M marked/NA12878_metrics.txt
# Indexing duplicates.
gatk BuildBamIndex -I marked/NA12878_marked.bam

# 5. BQSR (Base Quality Score Recalibration).
# Corrects systematic errors in base quality scores, using known variant sites

# Create `BQSR` directory for output files.
mkdir -p BQSR

# Prepare recalibration table with modeled errors.
gatk BaseRecalibrator -I marked/NA12878_marked.bam -R /tmp/ref/chr7.fa

# BAM file recalibration using prepared table with modeled errors. 
gatk ApplyBQSR -I marked/NA12878_marked.bam -R /tmp/ref/chr7.fa

# 6. Variant Calling.
# Search variants in the aligned reads.

# Create `VCF` directory for output files.
mkdir -p VCF

# Call recalibrated reads for variants based on reference genome data.
gatk HaplotypeCaller -I BQSR/NA12878_recal.bam -R /tmp/ref/chr7.fa

# 7. Genotyping.
# Creating file for further analysis in Variant Effect Predictor (VEP).

# Transforming .g.vcf file to .vcf file containing a region of interest for analysis.
gatk GenotypeGVCFs -R /tmp/ref/chr7.fa -V VCF/NA12878.g.vcf.gz -O VCF/NA12878.vcf.gz -L chr7:117400000-117750000

# Look for number of variants found.
zcat NA12878.vcf.gz | grep -v "^#" | wc -l

# Look for first lines of the variant list.
zcat NA12878.vcf.gz | grep -v "^#" | head -n 5 | cut -f 1-6,10

# Look on the variants of the region of interest.
zcat NA12878.vcf.gz | grep -E "117548682|117548786" | cut -f 1-6,10 

# 8. Filtering.
# Applying filters to exclude false positive variants.

gatk VariantFiltration \
    -R /tmp/ref/chr7.fa \
    -V VCF/NA12878.vcf.gz \
    -O VCF/NA12878.filtered.vcf.gz \
    --filter-name "QD2"    --filter-expression "QD < 2.0" \
    --filter-name "QUAL30" --filter-expression "QUAL < 30.0" \
    --filter-name "FS60"   --filter-expression "FS > 60.0" \
    --filter-name "MQ40"   --filter-expression "MQ < 40.0"







 
