# CFTR Clinical Case Study: WGS Variant Analysis (Son vs Father) #

## Germline variant analysis of whole-genome sequencing data from a son and his father (1000 Genomes), from quality control to clinical interpretation of variants in the CFTR gene, using GATK-based pipeline. 
## No CF-causing variant was found. The son carries one benign variant and two variants of uncertain significance, all shared with his father.
## Full report: [CFTR_report.md](CFTR_report.md)

**Created as part of the HackBio internship Genome Data Science (Fundamentals)**

## Data

> **Samples:** 1000 Genomes Project, 30x WGS on GRCh38 (NYGC): son HG01502 (ERR3988891) and father HG01500 (ERR3241916), Iberian (IBS).

> **Sample selection:** 1000 Genomes pedigree file and sequence index files.

> **Reference genome:** GRCh38 chromosome 7, Broad Institute GATK resource bundle.

> **Known indels (BQSR):** chromosome 7 subset of <file name>

> **Region:** CFTR ±80 kb, chr7:117,400,000–117,750,000.

----------------------------------------------------------------------------------------------------------------------------

# Task







## Repository structure

```
Genome_Data_Science_HackBio/
├── README.md
└── Stage1_WGS/
    ├── README.md
    └── cftr_project
         ├── README.md
         ├── data/
         ├── images/
         ├── results/
         ├── 00_setup_references.sh
         ├── 01_get_data_cftr.sh
         ├── 02_pipeline.sh
         ├── start_session.sh
         └── CFTR_report.md

```
