#!/bin/bash

# Get the training sample: NA12878 (1000 Genomes high-coverage, 30X WGS, GRCh38).
# The course dataset was no longer available. 
# So, reads from the CFTR region were extracted from a public 1000 Genomes CRAM file.
# This file were converted back to FASTQ to start the pipeline from raw reads.
# Requires: 00_setup_references.sh (the chr7 reference is needed to decode the CRAM).

# CFTR (GRCh38): chr7:117,480,025-117,668,665, extended by ~80 kb on each side.
FTP=http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000G_2504_high_coverage
REGION=chr7:117400000-117750000

# Create a directory where to keep extracted for analysis samples' data.
mkdir -p ~/Documents/shared_data
cd ~/Documents/shared_data

# 1. Download the family file (PED) and the sample index files.
wget $FTP/20130606_g1k_3202_samples_ped_population.txt
wget $FTP/1000G_2504_high_coverage.sequence.index
wget $FTP/1000G_698_related_high_coverage.sequence.index

# 2. Record the chosen sample (NA12878: female, CEU; father NA12891, mother NA12892).
grep "NA12878" 20130606_g1k_3202_samples_ped_population.txt > training_sample.txt

# 3. Find the address of NA12878's CRAM file in the index files.
grep "NA12878" *.sequence.index | cut -f 1 | cut -d ':' -f 2- > cram_urls.txt

# 4. Extract only the CFTR region from the remote CRAM and convert it to BAM.
# -T: reference used to decode the CRAM (CRAM stores only differences from the reference).
# The CRAM address uses https://, while cram_urls.txt contains the ftp:// version. 
# I used https:// because samtools reads it more reliably.
CRAM=https://ftp.sra.ebi.ac.uk/vol1/run/ERR323/ERR3239334/NA12878.final.cram
samtools view -b -T /tmp/ref/chr7.fa -o NA12878_CFTR.bam $CRAM $REGION

# Check: number of reads extracted.
samtools view -c NA12878_CFTR.bam

# 5. Sort by read name, so the two reads of each pair are next to each other.
samtools sort -n -o NA12878_CFTR.namesorted.bam NA12878_CFTR.bam

# 6. Convert to paired FASTQ files (R1, R2).
# Reads whose mate lies outside the region (singletons) are discarded (/dev/null).
samtools fastq -1 NA12878_R1.fastq.gz -2 NA12878_R2.fastq.gz -0 /dev/null -s /dev/null -n NA12878_CFTR.namesorted.bam

# Check: the first read of R1.
zcat NA12878_R1.fastq.gz | head -n 4
