#!/bin/bash

# Get the project samples (boy and his father): HG01502 (boy, IBS) and HG01500 (father) (1000 Genomes high-coverage, 30X WGS, GRCh38).
# The course dataset was no longer available. 
# So, reads from the CFTR region were extracted from a public 1000 Genomes CRAM file.
# These reads were converted back to FASTQ to start the pipeline from raw reads.
# Only the CFTR region is extracted and converted back to paired FASTQ.
# Requires: references from 00_setup_references.sh (/tmp/ref/chr7.fa) (the chr7 reference is needed to decode the CRAM).


# Address of the 1000 Genomes high-coverage data folder.
FTP=http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000G_2504_high_coverage
# Region to extract: CFTR (GRCh38: chr7:117,480,025-117,668,665), extended by ~80 kb on each side.
REGION=chr7:117400000-117750000

# Create a directory where to keep extracted for analysis samples' data.
mkdir -p ~/Documents/shared_data
cd ~/Documents/shared_data

# 1. Download the family file (PED) and the sample index files.
# -nc command allows to avoid duplicates (file is not downloaded if it already exists).
wget -nc $FTP/20130606_g1k_3202_samples_ped_population.txt
wget -nc $FTP/1000G_2504_high_coverage.sequence.index
wget -nc $FTP/1000G_698_related_high_coverage.sequence.index


# 2. Find candidate children: father in the dataset ($3 != "0"), male ($5 == 1), European ($7 == "EUR").
# The command lists the first candidates on screen; sample HG01502 was chosen.
tail -n +2 20130606_g1k_3202_samples_ped_population.txt | awk '$3 != "0" && $5 == 1 && $7 == "EUR"' | head

# 3. Record the chosen trio member: HG01502 (boy, IBS), father HG01500, mother HG01501 (mother not analysed).
grep "HG01502" 20130606_g1k_3202_samples_ped_population.txt > project_sample.txt

# 4. Find the CRAM addresses of the boy (HG01502) and his father (HG01500) in the index files.
grep -E "HG01502|HG01500" *.sequence.index | cut -f 1 | cut -d ':' -f 2- > project_cram_urls.txt

# 5. Loop over the two samples, boy and father.

SAMPLES=(
	"HG01500"
	"HG01502")

for SAMPLE in "${SAMPLES[@]}"; do

# Switch samples' CRAM addresses from ftp:// to https:// because samtools reads it more reliably.
CRAM=$(grep "$SAMPLE" project_cram_urls.txt | sed 's|ftp://|https://|')

# Extract only the CFTR region from the remote CRAM into a BAM (-T: reference to decode the CRAM).
samtools view -b -T /tmp/ref/chr7.fa -o ${SAMPLE}_CFTR.bam $CRAM $REGION

# Check extracted number of reads.
samtools view -c ${SAMPLE}_CFTR.bam

# Sort by read name, so the two reads of each pair are next to each other.
samtools sort -n -o ${SAMPLE}_CFTR.namesorted.bam ${SAMPLE}_CFTR.bam

# Convert to paired FASTQ files (R1, R2).
# Reads whose mate lies outside the region (singletons) are discarded (/dev/null).
samtools fastq -1 ${SAMPLE}_R1.fastq.gz -2 ${SAMPLE}_R2.fastq.gz -0 /dev/null -s /dev/null -n ${SAMPLE}_CFTR.namesorted.bam

# Check the first read of R1.
zcat ${SAMPLE}_R1.fastq.gz | head -n 4

done
