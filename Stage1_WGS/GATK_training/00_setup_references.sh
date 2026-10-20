#!/bin/bash

# Setup of reference files for the GATK training pipeline (GRCh38, chromosome 7 only).
# Source: Broad Institute hg38 resource bundle (public Google Cloud bucket).
# Only chr7 is used because the analysed reads come from the CFTR region (7q31.2).
# Files are stored in /tmp/ref (large temporary disk in Google Cloud Shell).

# 
BROAD=https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0
mkdir -p /tmp/ref

# 1. Reference genome: extract chr7 from the remote GRCh38 FASTA.
# samtools uses the remote .fai index to download only chr7 (~154 MB), not the whole 3 GB genome.
samtools faidx $BROAD/Homo_sapiens_assembly38.fasta chr7 > /tmp/ref/chr7.fa

# 2. FASTA index (.fai): needed by samtools and GATK to access positions in the reference.
samtools faidx /tmp/ref/chr7.fa

# 3. BWA index (.amb, .ann, .bwt, .pac, .sa): needed by bwa mem for alignment.
bwa index /tmp/ref/chr7.fa

# 4. Sequence dictionary (.dict): needed by every GATK tool that reads the reference.
gatk CreateSequenceDictionary -R /tmp/ref/chr7.fa

# 5. Known indels for BQSR: download only the chr7 part of the Broad known-indels resource,
#    then index it (.tbi), which GATK requires.
#    Run inside /tmp/ref so that the downloaded remote index stays there.
cd /tmp/ref
bcftools view -r chr7 $BROAD/Homo_sapiens_assembly38.known_indels.vcf.gz -Oz -o known_indels_chr7.vcf.gz
bcftools index -t known_indels_chr7.vcf.gz
