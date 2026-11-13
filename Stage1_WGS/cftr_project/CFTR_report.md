**Introduction**

***Clinical case**.* A 6-year-old boy presents with chronic cough,
recurrent lung infections, poor weight gain despite adequate nutrition;
his sweat chloride level was 45 mmol/L. Clinical picture and laboratory
results raise the suspicion of cystic fibrosis (CF), an autosomal
recessive genetic disease. <span class="mark">\[1\]</span>

***CFTR function**.* CF is caused by pathogenic variants in the *CFTR*
gene which encodes CFTR protein (cystic fibrosis transmembrane
conductance regulator) responsible for an ion channel transport across
the cell membrane. When CFTR is dysfunctional, mucus is dehydrated,
thick and viscous. It accumulates in the lungs on the airway walls and
impairs clearance, which leads to ineffective cough and recurrent
infections <span class="mark">\[1,2\]</span>.

***CFTR mutations**.* More than 2,000 CFTR mutations have been described
<span class="mark">\[1\]</span> and grouped into five classes according
to how they affect the CFTR protein; the percentages below give the
proportion of people with CF who carry at least one mutation of each
class <span class="mark">\[3\]</span>. Class I mutations (e.g. G542X,
W1282X, R553X) result in no functional CFTR protein (22%). Class II
mutations (e.g. F508del, N1303K, I507del) cause misfolding of the CFTR
protein, so it cannot reach the cell membrane (88%). Class III “gating
mutations” (e.g. G551D, S549N) produce a protein that reaches the cell
membrane, but the channel does not open properly (6%). Class IV
mutations (e.g. D1152H, R347P, R117H) produce a channel with reduced
function (6%). Class V mutations (e.g. 3849+10kbC\>T, 2789+5G\>A, A455E)
reduce the amount of normal CFTR protein (5%).
<span class="mark">\[3\]</span>

***Genetic testing*** was indicated by the clinical picture (chronic
respiratory symptoms) and the laboratory result (intermediate sweat
chloride values, 30-59 mmol/L), and consistent with current diagnostic
Cystic Fibrosis Foundation consensus guidelines
<span class="mark">\[4\]</span>. This study assessed whether the
variants found in the son correspond to known CF-causing mutations.

**Data**

***Source and samples***. WGS data were obtained from the 1000 Genomes
Project 30x collection on GRCh38 (Illumina NovaSeq, PCR-free; New York
Genome Center) <span class="mark">\[5,6\]</span>. The pedigree file was
searched for a European (EUR) male child whose father was also
sequenced; the son HG01502 (Iberian, IBS) and his father HG01500 were
selected, and their run accessions (ERR3988891, ERR3241916) were
confirmed in the Sequence Read Archive <span class="mark">\[7\]</span>.
Both are healthy research participants without clinical information, so
the results describe these substitute individuals, not the patient in
the clinical scenario.

***CFTR region***. Whole-genome FASTQ files exceeded the available
storage, so reads were extracted with samtools directly from the remote
indexed CRAM files and converted back to paired FASTQ. The region
covered the CFTR gene (NCBI Gene ID 1080; GRCh38
chr7:117,480,025–117,668,665) <span class="mark">\[8\]</span> extended
by ~80 kb on each side (chr7:117,400,000–117,750,000), to include reads
overlapping the gene boundaries and nearby regulatory regions.

***Reference***. Reads were aligned to GRCh38 chromosome 7 from the
Broad Institute GATK resource bundle, which also provided the known
indel sites for BQSR <span class="mark">\[9\]</span>.

**Methods**

All steps were run in Bash in Google Cloud Shell, using three scripts
(reference preparation, sample extraction, main pipeline; see the
repository).

***Quality Control and Trimming***. FastQC
<span class="mark">\[17\]</span> on raw reads to detect read quality
problems that could bias alignment and variant calling; fastp
<span class="mark">\[18\]</span> in paired-end mode to remove
low-quality bases and adapters.

***Alignment***. BWA-MEM with read groups (-R "@RG\tID:…\tSM:…"),
required by GATK to distinguish samples
<span class="mark">\[9,10\]</span>. Reads were aligned to the whole
chromosome 7, so that reads from elsewhere are not forced onto CFTR.

***Sorting, Duplicates, BQSR**.* GATK framework; SortSam (orders reads
by genomic coordinates), MarkDuplicates (mark the identical sequences to
avoid false positives during variant calling), BaseRecalibrator and
ApplyBQSR with known indels (corrects systematic base quality errors to
avoid misinterpretation of sequencing errors as true variants)
<span class="mark">\[9\]</span>.

***Variant Calling***. HaplotypeCaller per sample with -ERC GVCF and -L
chr7:117400000-117750000. GVCF mode also records positions matching the
reference, so that joint genotyping can assign a confident 0/0; -L
restricts calling to the extracted region (whole-chr7 calling exceeded
memory) <span class="mark">\[9\]</span>.

***Joint Genotyping***. CombineGVCFs merged both samples into one file,
with one row per position and one column per person followed by
GenotypeGVCFs that assigned final genotypes to both samples together;
0/0 means confident absence, not missing data
<span class="mark">\[9\]</span>.

```
# Combining genotypes.
gatk CombineGVCFs -R /tmp/ref/chr7.fa -V cftr_VCF/HG01502.g.vcf.gz -V
cftr_VCF/HG01500.g.vcf.gz -O cftr_VCF/family.g.vcf.gz -L
chr7:117400000-117750000

# **Joint genotyping.**
gatk GenotypeGVCFs -R /tmp/ref/chr7.fa -V cftr_VCF/family.g.vcf.gz -O
cftr_VCF/family.vcf.gz -L chr7:117400000-117750000
```

***Filtering***. For site-level filtering, GATK hard filters (QD \< 2
(QualByDepth, variant quality divided by read depth), QUAL \< 30
(variant confidence), FS \> 60 (FisherStrand, strand bias), MQ \< 40
(RMSMappingQuality, mapping quality)) were applied, because VQSR needs
many variants <span class="mark">\[9\]</span>. A genotype-level
allele-balanced filtering used bcftools <span class="mark">\[11\]</span>
and set heterozygous calls with \< 20% alternative reads to missing;
then only PASS sites were kept and indexed for region queries and
Integrative Genomic Viewer (IGV). CFTR region restriction using bcftools
was a final part of the filtering step.

```
# Site-level filtering.
gatk VariantFiltration -R /tmp/ref/chr7.fa -V cftr_VCF/family.vcf.gz -O
cftr_VCF/family.filtered.vcf.gz --filter-name "QD2" --filter-expression
"QD \< 2.0" --filter-name "QUAL30" --filter-expression "QUAL \< 30.0"
--filter-name "FS60" --filter-expression "FS \> 60.0" --filter-name
"MQ40" --filter-expression "MQ \< 40.0"

# Genotype-level filtering, final site filtering and CFTR region
restriction with bcftools.
bcftools filter -S . -e 'GT="het" & FMT/AD\[:1\]/FMT/DP \< 0.2'
family.filtered.vcf.gz -Oz -o family.filtered_ab.vcf.gz
bcftools view -f PASS family.filtered_ab.vcf.gz -Oz -o
family.pass.vcf.gz
bcftools view -r chr7:117480025-117668665 family.pass.vcf.gz -Oz -o
family.CFTR.vcf.gz
```

***Comparison***. Variants with genotypes were extracted with \`bcftools
query\` into .tsv file and classified with \`awk\` into four groups:
shared / son-only / son has no variant / missing.

```
# Creating a .tsv file for better data access to compare inheritance
pattern.
bcftools query -f '%POS\t%REF\t%ALT\t\[%GT\t\]\n'
cftr_VCF/family.CFTR.vcf.gz \> cftr_genotypes.tsv

# Comparison of son/father genotypes.
awk -F'\t' '{f=\$4; b=\$5; gsub(/\\/,"/",f); gsub(/\\/,"/",b);
if (b=="./." \|\| f=="./.") cat="missing in son or father";
else if (b=="0/0") cat="father only";
else if (f=="0/0") cat="son only (maternal or de novo)";
else cat="shared with father (possibly paternal)";
print cat}' cftr_genotypes.tsv \| sort \| uniq -c
```

***Annotation***. Ensembl Variant Effect Predictor (VEP) web tool
(GRCh38, release 2026-07) <span class="mark">\[12\]</span> was used to
determine the predicted consequence of each variant (e.g. missense,
intronic).

```
# Genotype data for both samples for 4 annotated missense variants.
bcftools query -H -r
chr7:117548682,chr7:117559479,chr7:117590400,chr7:117592169 -f
'%POS\t%REF\t%ALT\t\[%GT:%AD\t\]\n' cftr_VCF/family.CFTR.vcf.gz
```

***Visualization***. missense and son-only calls (recalibrated BAMs and
final VCF files) were inspected in IGV <span class="mark">\[13\]</span>
to distinguish real calls from artefacts. IGV shows the reads supporting
each call.

***Interpretation***. Variants annotated in VEP were analysed using
ClinVar <span class="mark">\[14\]</span>, gnomAD
<span class="mark">\[15\]</span>, CFTR2 database
<span class="mark">\[23\]</span> and literature
<span class="mark">\[22,24\]</span>, because all these sources provide
clinical classification, population frequency, CF-specific evidence
helping to interpret their possible clinical effect.

**Results**

***Quality Control, Trimming, Alignment**.* Both samples had 150 bp
reads, 36% GC and no poor-quality sequences; the son had more reads.
Base quality was Phred 30 throughout, but this plot is uninformative
because the source data store binned quality scores. Adapter content and
overrepresented sequences passed. “Per sequence GC content” gave warning
in both samples: the read GC content (36%) matches the reference region
itself (37%), which is below the genome-wide average (~41%)
<span class="mark">\[16\]</span>. FastQC compares the data with a normal
distribution <span class="mark">\[17\]</span> and reads from a single
350 kb locus do not follow one, so the warning does not indicate
contamination. “Per tile sequence quality” warning in father only showed
only a few thin, scattered lines which indicate minor random
fluctuations.

```
# GC content calculation for a reference region.
samtools faidx /tmp/ref/chr7.fa chr7:117400000-117750000 \| grep -v "\>"
\| tr -d '\n' \| awk '{n=length(\$0); gc=gsub(/\[GCgc\]/,""); printf "GC
= %.1f%%\n", 100\*gc/n}'

GC = 37.0%
```

Trimming removed less than 1% of bases, 99.6% (father) and 99.5% (son)
of reads passed the filters, and Q30 and GC content were essentially
unchanged. More than 99.9% of reads mapped to chromosome 7 and over
99.8% were properly paired (\`samtools flagstat\`), confirming that read
pairs were rebuilt correctly when converting back to FASTQ.
MarkDuplicates flagged 11.8% (father) and 7.8% (son) of read pairs as
duplicates.

***Variant Calling, Joint Genotyping*.** Separate calling identified 386
(son) and 380 (father) candidate variant positions differing from the
reference genome. The merged file contained 573 variant positions
instead of 766, because 193 positions were present in both samples.

Joint genotyping assigned each sample the most probable genotype from
the proportion of reference and alternative reads (~0% is 0/0 genotype,
~50% is 0/1 genotype, ~100% is 1/1 genotype, where 0 = reference allele
and 1= alternative allele; ./. = no call). 359 of the 573 positions,
where at least one sample had a non-reference genotype, were retained.
The symbols “\|” and “/” denote phased and unphased genotypes, i.e.
whether it is known which chromosome copy carries each allele.

***Filtering*.** Of the four site-level filters (QD \< 2, QUAL \< 30, FS
\> 60, MQ \< 40), only QD and MQ flagged sites for four low-quality
variant positions: 1 MQ40 (117526735), 3 QD2 (117423689, 117500202,
117560645). These were removed leaving 355 positions. Allele-level
filter with a threshold 20% for alternative allele identified 16 missing
genotypes (./.), there were other 2 no-calls from GenotypeGVCFs.
Altogether, 18 genotypes were missing across 15 positions. These
positions included the 3 that failed site-level filtering. Allele-level
filtering did not remove any variant rows, because it acts only on
individual genotypes. After CFTR region restriction 163 positions were
located in the CFTR gene.

***Comparison***. Comparison of inheritance patterns revealed that 151
variants were shared between son and father, 6 variants were found only
in the son (father 0/0), 1 only in the father (117538313T\>C; father 10
reference / 15 alternative reads, son 30 / 0), and 5 positions had a
missing genotype (./.) in one of the two, including the 117548682C\>A
artefact. Without the mother’s sample, the origin of shared variants
(paternal or maternal) and son-only variants (maternal or de novo)
cannot be fully resolved.

***Annotation*.** VEP annotation of the 163 CFTR positions identified 4
missense calls (***Table 1***); none of the 6 son-only variants was
protein-altering. A position 117548682 did not have a trusted variant in
any sample: neither the son (genotype 0/0 with 38 reference and 0
alternative reads), nor the father (genotype ./. with 17 reference and 4
alternative reads, so only 4 of 21 reads carried the alternative allele
(19%), so the allele filter set it to ./.). So, this call was considered
an artefact. In gnomAD, this site failed quality filters in both exomes
and genomes and had a flag for discrepant exome/genome frequencies
<span class="mark">\[15,19\]</span>. The other three annotated missense
variants were heterozygous in both son and father: 117559479G\>A (father
0/1:13,12, son 0/1:13,12); 117590400G\>C (father 0/1:10,10, son
0/1:16,19); 117592169C\>T (father 0/1:19,20, son 0/1:20,27).

ClinVar classified 117559479G\>A as benign/likely benign, and
117590400G\>C and 117592169C\>T as conflicting, mostly uncertain
significance <span class="mark">\[14\]</span>. In gnomAD database,
allele frequency of the 117559479G\>A benign missense variant was 43.91%
for total population and 54.93% for European population. For VUS
missense variants: 117590400G\>C had total population 0.68% and European
population 0.83% frequency; 117592169C\>T had total population 0.82% and
European population 1% frequency <span class="mark">\[15,19\]</span>.

***IGV Review*.** IGV visually confirmed heterozygosity of 3 missense
variants (117559479G\>A, 117590400G\>C, 117592169C\>T) and artefact
nature of 117548682C\>A variant (Figures are presented in GitHub
repository). For all three missense variants about half of reads carried
the alternative allele (48–57%) in both son and father. At 117548682,
the father had only a few alternative reads, and the sporadic A bases in
the son were in low-quality reads not counted by GATK. For son-only
variants, IGV confirmed variants 117500580G\>A, 117533171C\>T,
117599550G\>C, 117655321G\>A, 117661274G\>A as heterozygous (34–70%
alternative reads in the son, none in the father). 117500278C\>CT is an
insertion in a poly-T homopolymer with low depth (7 reads). Homopolymers
are prone to sequencing and alignment errors, so this call was
considered an artefact <span class="mark">\[21\]</span>.

***Table 1. Missense variants in CFTR.***

| **Position**  | **Protein**         | **Father (ref,alt)** | **Son (ref,alt)** | **ClinVar <span class="mark">\[14\]</span>** | **gnomAD Total / European <span class="mark">\[15\]</span>** | **CFTR2 <span class="mark">\[23\]</span>** | **Conclusion** |
|---------------|---------------------|----------------------|-------------------|----------------------------------------------|--------------------------------------------------------------|--------------------------------------------|----------------|
| 117548682C\>A | –                   | ./. (17,4)           | 0/0 (38,0)        | Conflicting                                  | 0.26% / 1.1%, failed gnomAD QC                               | –                                          | Artefact       |
| 117559479G\>A | p.Val470Met (M470V) | 0/1 (13,12)          | 0/1 (13,12)       | Benign/likely benign                         | 43.91% / 54.93%                                              | Non CF-causing                             | Benign, shared |
| 117590400G\>C | p.Gly576Ala         | 0/1 (10,10)          | 0/1 (16,19)       | Conflicting, mostly VUS                      | 0.68% / 0.83%                                                | No interpretation                          | VUS, shared    |
| 117592169C\>T | p.Arg668Cys         | 0/1 (19,20)          | 0/1 (20,27)       | Conflicting, mostly VUS                      | 0.82% / 1.00%                                                | No interpretation                          | VUS, shared    |

**Interpretation**

Cystic fibrosis is an autosomal recessive disorder, so it requires
pathogenic variants on both copies of CFTR for its manifestation. The
three missense variants were heterozygous, each present on only one
copy. The son shared the three missense variants with his father. So,
the variants are possibly paternal, but maternal origin cannot be
excluded. None of the variants corresponds to a known CF-causing
mutation (see Introduction): all of them have either benign, or
conflicting benign/uncertain pathogenicity based on ClinVar data.

The benign variant 117559479G\>A (p.Val470Met, M470V) had allele
frequency 54.93% in Europeans with 164,304 homozygotes according to
gnomAD database <span class="mark">\[15\]</span>. A variant this common
cannot cause a rare, severe disease <span class="mark">\[20\]</span>.
The CFTR2 database classifies it as "non CF-causing"
<span class="mark">\[22,23\]</span>.

Neither of the other two missense variants, 117590400G\>C (p.Gly576Ala)
and 117592169C\>T (p.Arg668Cys), has an individual interpretation in
CFTR2 (version 30 January 2026), but their combination, the complex
allele p.\[Gly576Ala;Arg668Cys\] described in the literature
<span class="mark">\[24\]</span>, is classified as non CF-causing
<span class="mark">\[23\]</span>. In ClinVar, both have conflicting
classifications, mostly of uncertain significance
<span class="mark">\[14\]</span>. Both son and father are heterozygous
for both variants, which is consistent with the two variants lying
together on one chromosome (in cis), inherited from the father; however,
the phase was not determined.

In the tested individual no CF-causing variant was found: the son
carries one benign variant and two VUS, which are classified as non
CF-causing when combined as a complex allele, if they lie on the same
chromosome. Thus, cystic fibrosis cannot be genetically confirmed in the
patient.

**Conclusion**

Cystic fibrosis is not genetically confirmed in the son, but it cannot
be excluded; further diagnostic steps are therefore recommended.
Recommendations: test the mother’s sample (to clarify the origin of the
son-only variants and the phase of the two VUS); further clinical
evaluation (repeated sweat test <span class="mark">\[4\]</span>); nasal
potential difference (NPD) or intestinal current measurements (ICM) as a
second line in case of inconclusive sweat test
<span class="mark">\[25\]</span>; and CFTR deletion/duplication analysis
(e.g. MLPA) <span class="mark">\[26,27\]</span>.

**Limitations**

**Samples**: The analysed samples were public substitutes for the
clinical case, so the results describe healthy research participants
without phenotype data, not the patient.

**Mother**: The mother was not tested, so the origin of the son-only
variants (maternal or de novo) and the phase of the two VUS could not be
determined.

**CRAM files**: Reads were extracted from an existing 1000 Genomes
alignment, so only reads already mapped to this region were retrieved;
reads from the region that the original alignment placed elsewhere were
missed. Base qualities were binned, which limits quality-based steps
such as BQSR.

**Site filters**: Four filters were applied together to SNPs and indels:
QD, QUAL, FS, MQ, while GATK recommends <span class="mark">\[9\]</span>
separate thresholds for SNPs and indels and further filters (SOR,
MQRankSum, ReadPosRankSum).

**Allele filters**: The 20% threshold is a rule of thumb rather than a
statistically derived value, so it may remove true low-fraction variants
or keep some artefacts. The filter used only the first ALT allele
(AD\[:1\]), so three 0/2 heterozygous genotypes at multi-allelic repeat
sites in the son were wrongly set to missing.

**Short reads**: Short-read data cannot detect large
deletions/duplications, and the intron 9 poly-T/TG tract is difficult to
resolve <span class="mark">\[27\]</span>.

**Region**: Only the CFTR region (±80 kb) was analysed, so variants
outside this region (distant regulatory elements, modifier genes) were
not assessed.

**Interpretation**: In silico prediction of the effect on the protein
(SIFT, PolyPhen) was not evaluated, so the consequence for the protein
does not have full interpretation. ACMG/AMP criteria were not applied,
so the variants were not formally classified; the interpretation relied
on existing database classifications.

**References**

1.  Grasemann H, Ratjen F. Cystic Fibrosis. *N Engl J Med.*
    2023;389(18):1693–1707.

2.  Myer H, Chupita S, Jnah A. Cystic Fibrosis: Back to the Basics.
    *Neonatal Netw.* 2023;42(1):23-30.

3.  Cystic Fibrosis Foundation. Types of CFTR mutations.
    [https://www.cff.org/research-clinical-trials/types-cftr-mutations.
    Accessed 28 October
    2026](https://www.cff.org/research-clinical-trials/types-cftr-mutations.%20Accessed%2028%20October%202026).

4.  Farrell PM, White TB, Ren CL, et al. Diagnosis of Cystic Fibrosis:
    Consensus Guidelines from the Cystic Fibrosis Foundation. *J
    Pediatr.* 2017;181S:S4–S15.e1.

5.  Fairley S, Lowy-Gallego E, Perry E, Flicek P. The International
    Genome Sample Resource (IGSR) collection of open human genomic
    variation resources. *Nucleic Acids Res.* 2020;48(D1):D941–D947.

6.  Byrska-Bishop M, Evani US, Zhao X, et al. High-coverage whole-genome
    sequencing of the expanded 1000 Genomes Project cohort including 602
    trios. *Cell.* 2022;185(18):3426–3440.e19.

7.  SRA Explorer. <https://sra-explorer.info/> (accessed 27 October
    2026).

8.  NCBI Gene. CFTR, Gene ID 1080.
    <https://www.ncbi.nlm.nih.gov/gene/1080> (accessed 27 October 2026).

9.  Broad Institute. GATK Resource Bundle. GATK documentation.
    <https://gatk.broadinstitute.org/hc/en-us/articles/360035890811>
    (accessed 28 October 2026).

10. Li H. Aligning sequence reads, clone sequences and assembly contigs
    with BWA-MEM. arXiv. 2013;arXiv:1303.3997v2 \[q-bio.GN\].

11. Danecek P, Bonfield JK, Liddle J, et al. Twelve years of SAMtools
    and BCFtools. GigaScience. 2021;10(2):giab008.

12. McLaren W, Gil L, Hunt SE, et al. The Ensembl Variant Effect
    Predictor. Genome Biol. 2016;17(1):122.

13. Robinson JT, Thorvaldsdóttir H, Winckler W, et al. Integrative
    genomics viewer. Nat Biotechnol. 2011;29(1):24–26.

14. Landrum MJ, Chitipiralla S, Kaur K, Brown G, et al. ClinVar: updates
    to support classifications of both germline and somatic variants.
    Nucleic Acids Res. 2025 Jan 6;53(D1):D1313-D1321.

15. gnomAD v4.1 (Genome Aggregation Database).
    <https://gnomad.broadinstitute.org/> (accessed 28 October 2026).
    Release description: [gnomAD v4.0 release
    post](https://gnomad.broadinstitute.org/news/2023-11-gnomad-v4-0).

16. International Human Genome Sequencing Consortium. Initial sequencing
    and analysis of the human genome. Nature. 2001;409:860–921.

17. Andrews S. FastQC: a quality control tool for high throughput
    sequence data. 2010. Available from:
    <https://www.bioinformatics.babraham.ac.uk/projects/fastqc/>
    (accessed 30 October 2026).

18. Chen S, Zhou Y, Chen Y, Gu J. fastp: an ultra-fast all-in-one FASTQ
    preprocessor. Bioinformatics. 2018;34(17):i884–i890.

19. Kore P, Wilson MW, Tiao G et al*.* Improved allele frequencies in
    gnomAD through local ancestry inference. 2025. *Nat Commun*. 16,
    8734.

20. Richards S, Aziz N, Bale S, et al. Standards and guidelines for the
    interpretation of sequence variants. Genet Med. 2015;17(5):405–424.

21. Laehnemann D, Borkhardt A, McHardy AC. Denoising DNA deep sequencing
    data—high-throughput sequencing errors and their correction. Brief
    Bioinform. 2016;17(1):154–179.

22. Sosnay PR, Siklosi KR, Van Goor F, Kaniecki K et al. Defining the
    disease liability of variants in the cystic fibrosis transmembrane
    conductance regulator gene. Nat Genet. 2013 Oct;45(10):1160-7.

23. CFTR2 database (Clinical and Functional Translation of CFTR),
    version 30 January 2026: <https://cftr2.org/mutations_history>
    (accessed 31 October 2026).

24. El-Seedy A, et al. CFTR mutation combinations producing frequent
    complex alleles with different clinical and functional outcomes. Hum
    Mutat. 2012;33(11):1557–65.

25. Bienvenu T, Lopez M, Girodon E. Molecular Diagnosis and Genetic
    Counseling of Cystic Fibrosis and Related Disorders: New Challenges.
    Genes (Basel). 2020 Jun 4;11(6):619.

26. Dequeker E, Stuhrmann M, Morris MA, et al. Best practice guidelines
    for molecular genetic diagnosis of cystic fibrosis and CFTR-related
    disorders – updated European recommendations. Eur J Hum Genet.
    2009;17(1):51–65.

27. Pagin A, Devos A, Figeac M, Truant M, Willoquaux C, Broly F,
    Lalau G. Applicability and Efficiency of NGS in Routine Diagnosis:
    In-Depth Performance Analysis of a Complete Workflow for CFTR
    Mutation Analysis. PLoS One. 2016 Feb 22;11(2):e0149426.
