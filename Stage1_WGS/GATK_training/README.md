# Variant Detection with GATK (Genome Analysis Toolkit) pipeline. #

## Objective: Analysis of a genome sequencing data issued from WGS and restricted to the CFTR region with the aim to identify possible pathogenic variants in an individual.

**Created as part of the HackBio internship Genome Data Science (Fundamentals)**

> **Data: 1000 Genomes Project (NA12878, 30X WGS)**
> 
> **Reference files: Broad Institute hg38 resource bundle**
> 
> **Sample files: NA12878 paired-end reads (R1, R2), CFTR region**

### Files required for analysis:

* Reference Genome: GRCh38 chromosome 7 (`chr7.fa`, `chr7.fa.fai`, `chr7.dict`; BWA index files: `chr7.fa.amb`, `chr7.fa.ann`, `chr7.fa.bwt`, `chr7.fa.pac`, `chr7.fa.sa`)
* Known indel sites on chromosome 7 (`known_indels_chr7.vcf.gz` + `known_indels_chr7.vcf.gz.tbi`)
* Sample Genome (`NA12878_R1.fastq.gz`, `NA12878_R2.fastq.gz`)
* 1000 Genomes sample index files (`1000G_2504_high_coverage.sequence.index`, `1000G_698_related_high_coverage.sequence.index`)

--------------------------------------------------------------------

## Task

* Analyze eukaryotic human previously processed WGS data including steps: 
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
* Search for possible pathogenic variants.

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

### 1. Setup reference data.

* Use the public Broad Institute hg38 resource bundle.
* Extract chromosome 7 and download files with reference genome data.
* Download files with index data for alignment and BQSR.

### 2. Setup sample data. 

* NA12878 (the daughter in CEPH trio 1463) was selected as the best-characterised benchmark genome.
* Find the address of NA12878’s CRAM file in the 1000 Genomes index files.
* Extract only the CFTR region from the remote CRAM file.
* Sort reads by names to pair them properly.
* Reads were converted to FASTQ with `samtools fastq` (equivalent to `gatk SamToFastq`).
* Pair-end reads were used for analysis, so there were two analysed sample files.

### 3. WGS data analysis with GATK framework.

* ***Quality Control:*** 

This step was performed as a required part of NGS data analysis using `fastqc` tool. 

Both reads had warning flags for "Per tile sequencing quality" and for "Per sequence GC content" modules. 

The per-tile warning showed only small random fluctuations, common on NovaSeq flow cells.

GC warning was expected, because the reads come from a single 350 kb region rather than the whole genome.

There were no fail flags for any module. 

All base qualities appear as Phred 30 because the source CRAM files store binned quality scores, which makes the per-base quality plot uninformative.

* ***Trimming:***

Trimming was included as an additional QC step.

GATK Best Practices consider it optional, since BWA-MEM soft-clips residual adapter sequence.

* ***Alignment:***

Reads were aligned with `bwa mem` to GRCh38 chromosome 7, adding read groups (`-R`) required by GATK.

The output was converted to BAM with `samtools view -b` in the same command.

* ***Sorting and Marking Duplicates:***

From this step, GATK framework was applied.

`gatk SortSam` sorted reads by genomic coordinate. 

`gatk MarkDuplicates` flagged PCR and optical duplicates (10.8% of read pairs, including 817 optical duplicate pairs) so they are not counted as independent evidence.

`BuildBamIndex` indexed the result.

* ***BQSR:***

The sequencer’s quality scores contain systematic errors. 

`BaseRecalibrator` measured these errors, using known indel sites so that real variants are not counted as errors. 

`ApplyBQSR` then corrected (recalibrated) the quality scores based on the `BaseRecalibrator` measurements.

* ***Variant Calling:***

`gatk HaplotypeCaller` called variants from the recalibrated reads.

`HaplotypeCaller` was run in GVCF mode (`-ERC GVCF`), restricted to the CFTR region with `-L` (without it, the run failed with an out-of-memory error).

* ***Genotyping:***

Using `gatk GenotypeGVCFs`, the final VCF file was obtained. 

The VCF file contains characteristics of all variants issued from analysis of the sample reads.

Based on these characteristics, variants can be filtered for the final annotation step.

***Observing called variants after genotyping and before filtering in VEP:***

*files:* NA12878.vcf

*genome:* GRCh38.p14

*image:* 

Protein-altering variants are present:

<img src="images/VEP_GATK_training_before_Filtering.png" width="1200">

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

* ***Filtering:***

Three tools were used for variant filtration.

`gatk VariantFiltration` flagged variants that failed GATK’s standard hard filters: QD < 2 (low quality relative to depth), QUAL < 30 (low confidence), FS > 60 (strand bias) and MQ < 40 (poor mapping quality).

These let two low-quality calls pass, so `bcftools filter` added an allele-balance filter (< 20% of depth: variants supported by less than 20% of reads were marked as LowAB). 

`bcftools view` kept only the variants that passed all filters (PASS).

***Observing called variants after filtering in VEP:***

*files:* NA12878.pass.vcf

*genome:* GRCh38.p14

*image:* 

No protein-altering variants:

<img src="images/VEP_GATK_training_after_Filtering.png" width="1200">

* ***Annotation:***

At this stage no code was used.

The annotation stage was performed using Ensembl Variant Effect Predictor (VEP) online tool. 

Before filtering, the list of variants included 68 positions. 

Three clustered calls were found within 15 bp, supported by the same four reads. 

```
chr7    117548682       .       C       A       59.64   QD2
chr7    117548786       .       AGTT    A       79.60   PASS
chr7    117548796       .       G       T       79.64   PASS
```

VEP classified two as protein-altering (missense, in-frame deletion) and one as synonymous. 

After filtering, 64 variants left, with no protein-altering variants remaining.

```
chr7    117548682       .       C       A       59.64   QD2;LowAB
chr7    117548786       .       AGTT    A       79.6    LowAB
chr7    117548796       .       G       T       79.64   LowAB
```

These protein-altering calls were artefacts, most likely misaligned reads next to a repetitive region (see IGV).

## Skills demonstrated

* End-to-end germline variant calling on WGS data (GATK Best Practices)
* Quality control and interpretation of FastQC reports
* Working with SAM/BAM/CRAM, VCF and GVCF formats
* Extraction of a genomic region from public remote data (1000 Genomes, Broad bucket)
* Variant filtering, including a custom allele-balance filter
* Visual validation of variant calls in IGV
* Variant annotation with Ensembl VEP
* Critical evaluation of false-positive calls
* Reproducible Bash scripting and version control with Git/GitHub
* Working within limited computing resources (Google Cloud Shell)

## Tools

* FastQC, fastp
* BWA-MEM
* samtools, bcftools
* GATK 4.6 (SortSam, MarkDuplicates, BuildBamIndex, BaseRecalibrator, ApplyBQSR, HaplotypeCaller, GenotypeGVCFs, VariantFiltration, CreateSequenceDictionary)
* IGV (web), Ensembl VEP (web)
* conda, Google Cloud Shell, Git/GitHub

