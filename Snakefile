####################################################################################################
########## This is a pipeline to call variants from WGS data developed by Ariel Xu #################
####################################################################################################

#INPUT_ID=["bb"]

#Libraries
import pandas as pd 

#Load configuration file
configfile: "/mtDNA_variant_call_pipeline/config/config.yml"

WORKING_DIR = config["working_dir"]
OUTPUT_DIR = config["results_dir"]
CONFIG_DIR = config["config_dir"]

#Parse input samples file, extract sample ids
units = pd.read_table(config["units"], dtype=str).set_index(["sample"], drop=False)

#Create sample ID list 
INPUT_ID = units.index.get_level_values('sample').unique().tolist()

#Check if SAMPLE_ID is provided via config. If so, use it
if "SAMPLE_ID" in config:
    if config["SAMPLE_ID"] in INPUT_ID:
        INPUT_ID = [config["SAMPLE_ID"]]  # Use the specific sample ID passed from dsub
    else:
        raise ValueError(f"Sample ID '{config['SAMPLE_ID']}' not found in units file.")


rule all:
    input:
        expand(OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus_splitted.vcf", SAMPLE_ID = INPUT_ID)
        #expand(OUTPUT_DIR + "/fq_files/{SAMPLE_ID}.fq", SAMPLE_ID = INPUT_ID),
        #expand(OUTPUT_DIR + "/sam_files_rCRS/{SAMPLE_ID}.sam", SAMPLE_ID = INPUT_ID)

# convert bam files (ideally NUMT filtered chrM reads (previously aligned to chrM with bwa))
# to fq files
rule bam_2_fq:
    input:
        bam = WORKING_DIR + "/input/{SAMPLE_ID}.bam"
    output:
        fq = OUTPUT_DIR + "/fq_files/{SAMPLE_ID}.fq"
    #threads: 1
    conda: f"{CONFIG_DIR}/samtools_ENV.yml"
    shell:
        '''
        samtools bam2fq {input.bam} > {output.fq}
        '''    
# align fq files to rCRS using bwa mem
rule bwa:
    input:
        fq =  OUTPUT_DIR + "/fq_files/{SAMPLE_ID}.fq"
    output:
        sam = OUTPUT_DIR + "/sam_files_rCRS/{SAMPLE_ID}.sam"
    params:
        reference = WORKING_DIR + "/chrM_reference/chrMref.fa"
    #threads: 1
    conda: f"{CONFIG_DIR}/bwa_ENV.yml"
    shell:
        '''
        bwa mem {params.reference} {input.fq} -K 100000000 -p -v 3 -Y > {output.sam}
        '''
# run variant calling script which used gatk mutect2 in mitochondrial mode
rule variant_calling_1:
    input:
        sam = OUTPUT_DIR + "/sam_files_rCRS/{SAMPLE_ID}.sam"
    output:
        vcf = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf"
    params:
        reference = WORKING_DIR + "/chrM_reference/chrMref.fa"
    #threads: 16
    conda: f"{CONFIG_DIR}/samtools_gatk_ENV.yml"
    shell:
        '''
        ./variant_calling_1.sh {input.sam} {params.reference}
        '''
# bgzip vcf file
rule bgzip_1:
    input:
        vcf = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf"
    output:
        vcf_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf.gz"
    #threads: 1
    shell:
        '''
        bgzip -i {input.vcf}
        '''

# index vcf.qz file
rule tabix_1:
    input:
        vcf_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf.gz"
    output:
        vcf_gz_tbi = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf.gz.tbi"
    params:
    #threads: 1
    conda: f"{CONFIG_DIR}/samtools_ENV.yml"
    shell:
        '''         
        tabix -p vcf {input.vcf_gz}
        '''

# split multiallelic variants
rule split_multiallele_1:
    input:
        vcf_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf.gz",
        vcf_gz_tbi = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf.gz.tbi"
    output:
        vcf_splitted = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted.vcf"
    params:
        reference = WORKING_DIR + "/chrM_reference/chrMref.fa"
    #threads: 1
    conda: f"{CONFIG_DIR}/samtools_gatk_ENV.yml"
    shell:
        '''
        gatk LeftAlignAndTrimVariants \
        -R {params.reference} \
        -V {input.vcf_gz} \
        -O {output.vcf_splitted} \
        --split-multi-allelics \
        --keep-original-ac
        '''

# filter for only variants with VAF > 50
rule filter_vcf_vaf_50:
    input:
        vcf_splitted = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted.vcf"
    output:
        vcf_filtered_vaf_50 = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf"
    params:
        SAMPLE_ID = INPUT_ID
    shell:
        '''
        cat {input.vcf_splitted} | grep '^#' >> {output.vcf_filtered_vaf_50}
        python3 filter_VAF.py {input.vcf_splitted} {params.SAMPLE_ID} {params.SAMPLE_ID}
        '''

# bgzip the filtered vaf > 50 vcf file
rule bgzip_2:
    input:
        vcf_filtered_vaf_50 = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf"
    output:
        vcf_filtered_vaf_50_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf.gz"
    #threads: 1
    shell:
        '''
        bgzip -i {input.vcf_filtered_vaf_50}
        '''

# index the filtered vaf > 50 vcf.gz file
rule tabix_2:
    input:
        vcf_filtered_vaf_50_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf.gz"
    output:
        vcf_filtered_vaf_50_gz_tbi = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf.gz.tbi"
    params:
    #threads: 1
    conda: f"{CONFIG_DIR}/samtools_ENV.yml"
    shell:
        '''         
        tabix -p vcf {input.vcf_filtered_vaf_50_gz}
        '''

# use the filtered vaf > 50 vcf.gz file to make a consensus referenece based on rCRS
rule make_consensus_reference:
    input:
        vcf_filtered_vaf_50_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf.gz",
        vcf_filtered_vaf_50_gz_tbi = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS_splitted_filtered.vcf.gz.tbi"
    output:
        consensus_ref = OUTPUT_DIR + "/consensus_reference_sequences/{SAMPLE_ID}_consensus_ref.fa"
    params: 
        reference = WORKING_DIR + "/chrM_reference/chrMref.fa"
    #threads: 1
    conda: f"{CONFIG_DIR}/htslib_bcftools_ENV.yml"
    shell:
        '''
        bcftools consensus -f {params.reference} {input.vcf_filtered_vaf_50_gz} > {output.consensus_ref}
        '''
rule variant_calling_2:
    input:
        consensus_ref = OUTPUT_DIR + "/consensus_reference_sequences/{SAMPLE_ID}_consensus_ref.fa",
        fq = OUTPUT_DIR + "/fq_files/{SAMPLE_ID}.fq"
    output:
        vcf = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf"
    conda: f"{CONFIG_DIR}/variant_calling_2_ENV.yml"
    shell:
        '''
        ./variant_calling_2.sh {input.consensus_ref} {input.fq} 
        '''
        
rule bgzip_3:
    input:
        vcf = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf"
    output:
        vcf_gz = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf.gz"
    #threads: 1
    conda: f"{CONFIG_DIR}/htslib_ENV.yml"
    shell:
        '''
        bgzip -i {input.vcf}
        '''

rule tabix_3:
    input:
        vcf_gz = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf.gz"
    output:
        vcf_gz_tbi = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf.gz.tbi"
    params:
    #threads: 1
    conda: f"{CONFIG_DIR}/samtools_ENV.yml"
    shell:
        '''         
        tabix -p vcf {input.vcf_gz}
        '''

rule split_multiallele_2:
    input:
        vcf_gz = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf.gz",
        vcf_gz_tbi = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus.vcf.gz.tbi"
    output:
        vcf_splitted = OUTPUT_DIR + "/vcf_files_consensus/{SAMPLE_ID}_variants_called_against_consensus_splitted.vcf"
    params:
        reference = OUTPUT_DIR + "/consensus_reference_sequences/{SAMPLE_ID}_consensus_ref.fa"
    #threads: 1
    conda: f"{CONFIG_DIR}/samtools_gatk_ENV.yml"
    shell:
        '''
        gatk LeftAlignAndTrimVariants \
        -R {params.reference} \
        -V {input.vcf_gz} \
        -O {output.vcf_splitted} \
        --split-multi-allelics \
        --keep-original-ac
        '''     

# rule bgzip_1:
#     input:
#         vcf = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf"
#     output:
#         vcf_gz = OUTPUT_DIR + "/vcf_files_rCRS/{SAMPLE_ID}_variants_called_against_rCRS.vcf.gz"
#     #threads: 1
#     shell:
#         '''
#         bgzip -i {input.vcf}
#         ''' 