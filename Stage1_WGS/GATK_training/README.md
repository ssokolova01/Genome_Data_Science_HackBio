# Variant Detection with GATK (Genome Analysis Toolkit) pipeline. #

## Objective: Analysis of a genome sequencing data issued from WGS and truncated for a more technically manageable data with the aim to identify possible pathological variants in an individual.

**Created as part of the HackBio internship Genome Data Science (Fundamentals)**

> **Data: 1000 Genomes Project (NA12878, 30X WGS)**
> **Reference files: Broad Institute hg38 resource bundle**
> **Sample files: NA12878 paired-end reads (R1, R2), CFTR region**

### Files required for analysis:

* Human Reference Genome (`/tmp/ref/Homo_sapiens_assembly38.fasta`)
* Human reference genome index (`/tmp/ref/Homo_sapiens_assembly38.fasta.fai`, `/tmp/ref/Homo_sapiens_assembly38.dict`, `/tmp/ref/Homo_sapiens_assembly38.bwa.index`)
* Known sites on the human genome (`Homo_sapiens_assembly38.known_indels.vcf.gz.tbi`)
* Sample Genome (`NA12878_R1.fastq.gz`, `NA12878_R2.fastq.gz`)
* Genome index files (`1000G_2504_high_coverage.sequence.index`, `1000G_698_related_high_coverage.sequence.index`)

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

```bash
Genome_Data_Science_HackBio/
├── README.md
└── Stage1_WGS/
    ├── README.md
    └── GATK_training
         ├── README.md
         ├── data/
         ├── images/
         ├── results/
         ├── 00_setup_references.sh
         ├── 01_get_data.sh
         ├── 02_pipeline.sh
         └── .gitignore   # excludes large files (FASTQ, BAM, CRAM)
 ```

------------------------------------------------------------------------

## Technical Details

For technical reasons (end of access to initial files and work from the personal Cloud Shell Google account), additional pre-analytical work was required.

Scripts were run from a working directory in Google Cloud Shell; large files were kept outside the repository.

### 1. Setup reference data for analysis.

* Find an open source database with human sequenced data.
* Truncate and download files with reference genome data.
* Download files with index data for alignment and annotation steps.

### 2. Setup sample data for analysis. 

* NA12878 (the daughter in CEPH trio 1463) was selected as the best-characterised benchmark genome.
* Find the address of NA12878’s CRAM file in the 1000 Genomes index files.
* Truncate and download files to leave only a region where data of analysis interest was located.
* Sort reads by names to pair them properly.
* Reads were converted to FASTQ with `samtools fastq` (equivalent to `gatk SamToFastq`).
* Pair-end reads were used for analysis, so there were two analysed sample files.

### 3. WGS data analysis with GATK framework.

* ***Quality Control:*** 

This step was performed as a required part of NGS data analysis using `fastqc` tool. 
Both reads had warning flags for "Per tile sequencing quality" and for "Per sequence GC content" modules. 
GC warning was expected, because the reads come from a single 350 kb region rather than the whole genome.
These warning flags can be explained by truncation during the sample preparation stage.
There were no fail flags for any module. 
All base qualities appear as Phred 30 because the source CRAM files store binned quality scores, which makes the per-base quality plot uninformative.

* ***Trimming:***

Trimming was included as an additional QC step. Bases already have required Phred score and no adapters.
GATK Best Practices consider it optional, since BWA-MEM soft-clips residual adapter sequence.

* ***Alignment:***

Reads were aligned with `bwa mem` to GRCh38 chromosome 7, adding read groups (`-R`) required by GATK.
The output was converted to BAM with `samtools view -b` in the same command.

* ***Sorting and Marking Duplicates:***

From this step, GATK framework was applied.
`gatk SortSam` sorted reads by genomic coordinate. 
`gatk MarkDuplicates` flagged PCR and optical duplicates (10.8% of read pairs) so they are not counted as independent evidence.
`BuildBamIndex` indexed the result.

* ***BQSR:***

`BaseRecalibrator` modelled systematic errors in base quality scores using known indel sites. This allows to avoid mistaking between real variation and errors. 
`ApplyBQSR` applied this model to recalibrate the base qualities.

* ***Variant Calling:***

File issued from the BQSR step was called for variants using `gatk HaplotypeCaller` tool. 
Recalibrated reads were called for variants based on the reference genome.
`HaplotypeCaller` was run in GVCF mode (`-ERC GVCF`), restricted to the CFTR region with `-L` (without it, the run failed with an out-of-memory error).

* ***Genotyping:***

Using `gatk GenotypeGVCFs`, the final VCF file was obtained. 
The VCF file contains characteristics of all variants issued from analysis of the sample reads.
Based on these characteristics, variants can be filtered for the final annotation step.

***Observing called variants after genotyping and before filtering in VEP:***

*files:* NA12878.vcf

*genome:* GRCh38.p14

*image:* 

Pathologic predicted molecular consequences are present:

<img src="images/VEP_GATK_training_before_Filtering.png" width="1200">

* ***Filtering:***

Three tools were used for variant filtration.
`gatk VariantFiltration` flagged variants failing GATK’s standard hard filters (QD < 2, QUAL < 30, FS > 60, MQ < 40). 
These let two low-quality calls pass, so `bcftools filter` added an allele-balance filter (alternate reads < 20% of depth). 
`bcftools view` kept only PASS variants: 64 of ~100.

***Observing recalibrated reads in IGV tool:***

*files:* BQSR/NA12878_recal.bam, BQSR/NA12878_recal.bai

*genome:* hg38; chr7:117,548,660-117,548,820

*image:* 

Aligned recalibrated reads:

<img src="images/IGV_GATK_training_NA12878.png" width="1200">

***Observing recalibrated reads with variant calls in IGV tool:***

*files:* BQSR/NA12878_recal.bam, BQSR/NA12878_recal.bai, VCF/NA12878.vcf.gz, VCF/NA12878.vcf.gz.tbi

*genome:* hg38; chr7:117,548,660-117,548,820

*image:* 

Aligned recalibrated reads with called variants:

<img src="images/IGV_Calls_GATK_training_NA12878.png" width="1200">

***Observing called variants after filtering in VEP:***

*files:* NA12878.pass.vcf

*genome:* GRCh38.p14

*image:* 

No pathogenic predicted molecular consequences are identified:

<img src="images/VEP_GATK_training_after_Filtering.png" width="1200">

* ***Annotation:***

At this stage no code was used.
The annotation stage was performed using Ensembl Variant Effect Predictor (VEP) online tool. 
Before filtering, the list of variants included 68 positions. 
Three clustered calls were found within 15 bp, supported by the same four reads. 
chr7    117548682       .       C       A       59.64   QD2
chr7    117548786       .       AGTT    A       79.60   PASS
chr7    117548796       .       G       T       79.64   PASS
VEP classified two as protein-altering (missense, in-frame deletion) and one as synonymous. 
After filtering, 64 variants left, with no pathogenic variants detected.
chr7    117548682       .       C       A       59.64   QD2;LowAB
chr7    117548786       .       AGTT    A       79.6    LowAB
chr7    117548796       .       G       T       79.64   LowAB
The pathogenic variants discovered before filtering are more likely artefacts left after sample data preparation.


