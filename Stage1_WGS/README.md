# Stage 1: Whole-Genome Sequencing (WGS)

Projects from the HackBio internship *Genome Data Science: Fundamentals*, Stage 1: germline short-variant analysis of WGS data with a GATK-based pipeline in Google Cloud Shell.

## Projects

| Project | Description |
|---|---|
| [GATK_training](GATK_training/) | Training run of the GATK germline pipeline on the reference sample NA12878: reads from the CFTR region of the 1000 Genomes high-coverage data, processed from QC and alignment to variant calling and filtering, to test the pipeline before the clinical case study. |
| [cftr_project](cftr_project/) | Clinical case study: son–father WGS analysis of the *CFTR* gene for suspected cystic fibrosis, from QC to clinical interpretation. |

## Shared setup
Both projects use GRCh38 chromosome 7 from the Broad Institute GATK resource bundle and the same Cloud Shell environment (`start_session.sh`).
