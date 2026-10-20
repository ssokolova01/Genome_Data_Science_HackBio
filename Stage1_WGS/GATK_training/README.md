# Variant Detection with GATK (Genome Analysis Toolkit) pipeline. #

## Analysis of a genome sequencing data issued from WGS and truncated for a more technically manageable data with the aim to identify possible pathological variants in an individual.

> **Dataset: 1000 Genomes Database, Broad Institute**

**Created as part of the HackBio internship Genome Data Science (Fundamentals)**

### Files required for analysis:

* Human Reference Genome (`/data/ref/Homo_sapiens_assembly38.fasta`)
* Human reference genome index (`/data/ref/Homo_sapiens_assembly38.fasta.fai`)
* Known sites on the human genome (`/data/ref/Homo_sapiens_assembly38.known_indels.vcf.gz`)
* Sample Genome (`/data/NA12878.fastq.gz`)
* Genome index files (`/data/ref/`)

--------------------------------------------------------------------

## Repository structure

```
Genome_Data_Science_HackBio/
|--- Stage1_WGS
        |--- GATK_training
                  |--- data/
                  |--- images/
                  |--- results/
                  |--- 00_setup_references.sh
                  |--- 01_get_data.sh
                  |--- 02_pipeline.sh
                  |--- .gitignore
```

