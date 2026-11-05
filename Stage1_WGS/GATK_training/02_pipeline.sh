#!/bin/bash

# 1. Quality Control (QC).
# Aim: Analyse the quality of the reads for base reliability and adapters content.

# Create `qc` directory for QC output files.
mkdir -p qc

# QC analysis for both reads in one command.
fastqc ~/Documents/shared_data/NA12878_R1.fastq.gz ~/Documents/shared_data/NA12878_R2.fastq.gz -o qc/

# 2. Trimming.
# Aim: Trim low-quality regions and adapters (if any). Here represents more as a training step, because data was treated repeatedly.

# Create `GATK_trimmed` directory for trimming output files.
mkdir -p GATK_trimmed

# Create a sample list (there is one sample name in this analysis).
SAMPLES=(
      "NA12878"
)

# Bash script to iterate over the samples and run fastp for paired-end reads.

for SAMPLE in "${SAMPLES[@]}"; do
# Input: ../shared_data/${SAMPLE}_R1.fastq.gz and ../shared_data/${SAMPLE}_R2.fastq.gz
# Output: GATK_trimmed/${SAMPLE}_R1.fastq.gz and GATK_trimmed/${SAMPLE}_R2.fastq.gz
# Generate an HTML report for each sample in GATK_trimmed/
         fastp \
                  -i "../shared_data/${SAMPLE}_R1.fastq.gz" \
                  -I "../shared_data/${SAMPLE}_R2.fastq.gz" \
                  -o "GATK_trimmed/${SAMPLE}_R1.fastq.gz" \
                  -O "GATK_trimmed/${SAMPLE}_R2.fastq.gz" \
                  --html "GATK_trimmed/${SAMPLE}_fastp.html"
                  
done

# 3. Alignment.
# Aim: Align reads against the reference genome (or genome part) to recreate a DNA sequence.

# Create `map` directory for alignment output files.
mkdir -p map

# Alignment, conversion of SAM to BAM and saving the output in one command.
bwa mem -R '@RG\tID:NA12878\tSM:NA12878\tPL:ILLUMINA' /tmp/ref/chr7.fa GATK_trimmed/NA12878_R1.fastq.gz GATK_trimmed/NA12878_R2.fastq.gz | samtools view -b -o map/NA12878_aligned.bam

# Check created .bam files.
samtools view map/NA12878_aligned.bam | head -n 5

# 4. Sorting and Marking Duplicates.
# Aim: sort reads by genome position, then mark PCR/optical duplicates so they do not count as independent evidence for variants.

# Create `sorted` and `marked` directories for sorted and marked output.
mkdir -p sorted 
mkdir -p marked

# Sorting reads and saving output file in prepared directory.
gatk SortSam -I map/NA12878_aligned.bam -O sorted/NA12878_sorted.bam -SORT_ORDER coordinate

# Marking duplicates and save the output files in prepared directories.
gatk MarkDuplicates -I sorted/NA12878_sorted.bam -O marked/NA12878_marked.bam -M marked/NA12878_metrics.txt
# Index the duplicate-marked BAM.
gatk BuildBamIndex -I marked/NA12878_marked.bam

# 5. BQSR (Base Quality Score Recalibration).
# Aim: Corrects systematic errors in base quality scores, using known variant sites.

# Create `BQSR` directory for output files.
mkdir -p BQSR

# Prepare recalibration table with modeled errors.
gatk BaseRecalibrator -I marked/NA12878_marked.bam -R /tmp/ref/chr7.fa --known-sites /tmp/ref/known_indels_chr7.vcf.gz -O BQSR/NA12878_recal.table

# BAM file recalibration using prepared table with modeled errors. 
gatk ApplyBQSR -I marked/NA12878_marked.bam -R /tmp/ref/chr7.fa --bqsr-recal-file BQSR/NA12878_recal.table -O BQSR/NA12878_recal.bam

# 6. Variant Calling.
# Aim: Search variants in the aligned reads.

# Create `VCF` directory for output files.
mkdir -p VCF

# Call recalibrated reads for variants based on reference genome data.
gatk HaplotypeCaller -I BQSR/NA12878_recal.bam -R /tmp/ref/chr7.fa -O VCF/NA12878.g.vcf.gz -ERC GVCF -L chr7:117400000-117750000

# 7. Genotyping.
# Aim: Creating file for further analysis in Variant Effect Predictor (VEP).

# Transforming .g.vcf file to .vcf file containing a region of interest for analysis.
gatk GenotypeGVCFs -R /tmp/ref/chr7.fa -V VCF/NA12878.g.vcf.gz -O VCF/NA12878.vcf.gz -L chr7:117400000-117750000

# Count the variants called (data lines only, header removed).
zcat VCF/NA12878.vcf.gz | grep -v "^#" | wc -l

# Show the first 5 variants: CHROM, POS, ID, REF, ALT, QUAL and the genotype column.
zcat VCF/NA12878.vcf.gz | grep -v "^#" | head -n 5 | cut -f 1-6,10

# Inspect the three clustered protein-changing calls flagged by VEP (later identified as artefacts).
zcat VCF/NA12878.vcf.gz | grep -E "117548682|117548786" | cut -f 1-6,10 

# 8. Filtering.
# Aim: Filter variants to exclude false positives.

# Apply GATK's standard filters: depth quality (QD), reads quality confidence (QUAL), strand bias, or Fisher Strand (FS), mapping quality (MQ).
gatk VariantFiltration \
    -R /tmp/ref/chr7.fa \
    -V VCF/NA12878.vcf.gz \
    -O VCF/NA12878.filtered.vcf.gz \
    --filter-name "QD2"    --filter-expression "QD < 2.0" \
    --filter-name "QUAL30" --filter-expression "QUAL < 30.0" \
    --filter-name "FS60"   --filter-expression "FS > 60.0" \
    --filter-name "MQ40"   --filter-expression "MQ < 40.0"

# Extra filter: flag variants with low allele balance (alt reads < 20% of depth).
# GATK hard filters let two clustered low-fraction artefacts pass (QD ~2.6); IGV confirmed they were artefacts.
bcftools filter -s LowAB -m+ -e 'FMT/AD[0:1] / FMT/DP < 0.2' VCF/NA12878.filtered.vcf.gz -Oz -o VCF/NA12878.filtered_ab.vcf.gz

# Keep only variants that passed all filters (input for VEP).
bcftools view -f PASS VCF/NA12878.filtered_ab.vcf.gz -Oz -o VCF/NA12878.pass.vcf.gz

# 9. Annotation. 
# Aim: Annotate variants with their predicted effect on genes and proteins.

# NA12878.pass.vcf.gz was annotated with Ensembl VEP (web interface, GRCh38, GENCODE 50). 
# See README.





 
