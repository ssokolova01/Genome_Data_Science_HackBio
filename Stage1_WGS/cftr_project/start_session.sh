conda activate bioenv
export REF_CACHE=/tmp/hts-ref/%2s/%2s/%s
alias gatk='PATH=/tmp/gatk_env/bin:$PATH /tmp/gatk_env/bin/gatk'

BROAD=https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0
GATK="/tmp/gatk_env/bin/gatk"

# 1. GATK
if [ ! -f $GATK ]; then
    echo "GATK missing - installing..."
    export CONDA_PKGS_DIRS=/tmp/conda_pkgs
    conda create -p /tmp/gatk_env -c bioconda -c conda-forge gatk4 -y
fi

# 2. chr7 reference + .fai
if [ ! -s /tmp/ref/chr7.fa ]; then
    echo "chr7 missing - downloading..."
    mkdir -p /tmp/ref
    samtools faidx $BROAD/Homo_sapiens_assembly38.fasta chr7 > /tmp/ref/chr7.fa
    samtools faidx /tmp/ref/chr7.fa
fi

if [ ! -f /tmp/ref/chr7.fa.fai ]; then
	samtools faidx /tmp/ref/chr7.fa
fi


# 3. bwa index
if [ ! -f /tmp/ref/chr7.fa.bwt ]; then
    echo "bwa index missing - building..."
    bwa index /tmp/ref/chr7.fa
fi

# 4. Sequence dictionary
if [ ! -f /tmp/ref/chr7.dict ]; then
    echo "dict missing - creating..."
    PATH=/tmp/gatk_env/bin:$PATH $GATK CreateSequenceDictionary -R /tmp/ref/chr7.fa
fi

# 5. Known indels for chr7
if [ ! -f /tmp/ref/known_indels_chr7.vcf.gz.tbi ]; then
    echo "known indels missing - downloading..."
    cd /tmp/ref
    bcftools view -r chr7 $BROAD/Homo_sapiens_assembly38.known_indels.vcf.gz -Oz -o known_indels_chr7.vcf.gz
    bcftools index -t known_indels_chr7.vcf.gz
fi

cd ~/Documents/cftr_project
echo "Session ready."
