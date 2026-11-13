# CFTR Clinical Case Study: WGS Variant Analysis (Son vs Father) #

## Germline variant analysis of whole-genome sequencing data from a son and his father (1000 Genomes), from quality control to clinical interpretation of variants in the *CFTR* gene, responsible for cystic fibrosis (CF), using a GATK-based pipeline. 
### No CF-causing variant was found. The son carries one benign variant and two variants of uncertain significance, all shared with his father. Full report: [CFTR_report.md](CFTR_report.md)

**Created as part of the HackBio internship Genome Data Science (Fundamentals)**

## Data

> **Samples:** 1000 Genomes Project, 30x WGS on GRCh38 (NYGC): son HG01502 (ERR3988891) and father HG01500 (ERR3241916), Iberian (IBS).
> 
> **Sample selection:** 1000 Genomes pedigree file and sequence index files.
> 
> **Reference genome:** GRCh38 chromosome 7, Broad Institute GATK resource bundle.
> 
> **Known indels (BQSR):** `known_indels_chr7.vcf.gz`, the chromosome 7 subset of `Homo_sapiens_assembly38.known_indels.vcf.gz` (Broad GATK bundle), created by `00_setup_references.sh`.
>
> **Region:** CFTR ±80 kb, chr7:117,400,000–117,750,000.

----------------------------------------------------------------------------------------------------------------------------

## Task

Analyse the WGS data to determine whether the child carries pathogenic variants in the *CFTR* gene.

Provided clinical data:

A 6-year-old boy with chronic respiratory symptoms, poor weight gain and a borderline sweat chloride test (45 mmol/L) is suspected of having cystic fibrosis. WGS data are available for the boy and his father; the mother’s data are not available.

Whole-genome data analysis includes:

* Perform quality control and align raw reads to the human reference genome.
* Call variants in the son and the father.
* Focus the analysis on the CFTR locus (7q31.2).
* Compare the son’s and father’s variants to determine inheritance patterns.
* Annotate and interpret variants to identify known pathogenic *CFTR* mutations (e.g., F508del, G542X, W1282X) using variant databases such as ClinVar.
* Conclude whether the son is affected with CF, and whether the variants are inherited or possibly de novo.

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

## Technical details

