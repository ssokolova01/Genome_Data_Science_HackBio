# CFTR Clinical Case Study: WGS Variant Analysis (Son vs Father) #

## Germline variant analysis of whole-genome sequencing data from a son and his father (1000 Genomes), from quality control to clinical interpretation of variants in the CFTR gene (the gene responsible for cystic fibrosis (CF)), using a GATK-based pipeline. 
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

Execute WGS data analysis to explore pathogenic variants in the CFTR gene of the child with the following interpretation. 

Whole-genome data analysis includes:

* Quality control and alignment of raw reads to the human reference genome.
* Variant calling in the son and the father.
* Genome restriction to the CFTR region.
* Comparison of the inheritance pattern of variants between the son and the father.
* Annotate and interpret variants to identify possible pathogenic mutations using variant databases.
* Conclude on whether the son is affected with CF based on genotype. Comment on the variant origin (inherited or de novo).

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
