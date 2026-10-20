# Variant Detection with GATK (Genome Analysis Toolkit) pipeline. #

## Objective: Analysis of a genome sequencing data issued from WGS and truncated for a more technically manageable data with the aim to identify possible pathological variants in an individual.

> **Dataset: 1000 Genomes Database, Broad Institute**

**Created as part of the HackBio internship Genome Data Science (Fundamentals)**

### Files required for analysis:

* Human Reference Genome (`/data/ref/Homo_sapiens_assembly38.fasta`)
* Human reference genome index (`/data/ref/Homo_sapiens_assembly38.fasta.fai`)
* Known sites on the human genome (`/data/ref/Homo_sapiens_assembly38.known_indels.vcf.gz`)
* Sample Genome (`/data/NA12878.fastq.gz`)
* Genome index files (`/data/ref/`)

--------------------------------------------------------------------

## Task

* Analyse eukaryotic human WGS data (already used for analysis) including steps: 
  * Quality Control (QC);
  * Trimming;
  * Alignment;
  * Sorting and Marking Duplicates;
  * Base Quality Score Recalibration (BQSR);
  * Variant Calling;
  * Genotyping;
  * Filtering;
  * Annotation.
* Apply GATK workflow after the alignment step of the analysis. 
* Search for possible pathological variants.

---------------------------------------------------------------------------

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

------------------------------------------------------------------------

## Technical Details

For technical reasons (end of access to initial files and work from the personal Cloud Shell Google account), additional pre-analytical work included.

Scripts were run from a working directory in Google Cloud Shell; large files were kept outside the repository.

### *1. Setup reference data for analysis.

* Find an open source database with human sequenced data.
* Truncate and download files with reference genome data.
* Download files with index data for alignment and annotation steps.

### *2. Setup sample data for analysis. 

* Download family file and record the sample of interest (only child was analysed).
* Find the index file required for analysis.
* Truncate and download files to leave only a region where data of analysis interest was located.
* Sort reads by names to pair them properly.
* Reads were converted to FASTQ with samtools fastq (equivalent to GATK SamToFastq).
* Pair-end reads were used for analysis, so there were two analysed sample files.

### *3. WGS data analysis with GATK framework.

* Quality Control: 
This step was performed as a required part of NGS data analysis. 
Both reads had warning flags for "Per tile sequencing quality" and for "Per sequence GC content" modules. 
These warning flags can be explained by truncation during the sample preparation stage.
There were no fail flags for any module. 
Phred score for all bases was at the level of 30 because the data underwent trimming in the previous analysis.

* Trimming:
This step was performed as a required part of the NGS data analysis.
Generally, this step could be skipped because of the previous data processing (bases already have required Phred score and there are no adapters).

* Alignment:
For alignment step, chromosome 7 CFTR region was extracted from ChGR38 reference genome.

* Sorting and Marking Duplicates:
Using SortSam tool, possible dulplicates were sorted based on the genomic coordinates established at the alignment step.
Using MarkDuplicates tool, duplicates were marked and put in the separate folder.

* BQSR


* Variant Calling


* Genotyping


* Filtering


* Annotation
At this stage no code was used.
The annotation stage was performed using Ensembl Variant Effect Predictor (VEP) online tool. 
Before filtering, two pathological variants were discovered in VEP. 
However, after filtering there were no pathological variants detected.
The pathological variants discovered before filtering are more likely artefacts left after sample data preparation.


