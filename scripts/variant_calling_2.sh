#!/bin/bash

## load modules
module load samtools
module load bwa
module load miniconda/4.9.2
module load gatk/4.2.1.0

CONSENSUS_REFERENCE=$1
CONSENSUS_INDEX=${CONSENSUS_REFERENCE%_consensus_ref.fa}-consensus

# get sample id
SAMPLE_ID_TEMP="${CONSENSUS_REFERENCE##*/}"
SAMPLE_ID="${SAMPLE_ID_TEMP%_consensus_ref.fa}"

FQ_INPUT=$2
SAM_OUTPUT="../sam_files_consensus/${SAMPLE_ID}_consensus.sam"

temp_dir="../tmp/"
vcf_dir="../vcf_files_consensus/"
consensus_dir="../consensus_reference_sequences/"

## create directory for the consensus reference
gatk CreateSequenceDictionary -R ${CONSENSUS_REFERENCE}

## index the reference sequence
samtools faidx ${CONSENSUS_REFERENCE}

## name this reference
bwa index ${CONSENSUS_REFERENCE} -p ${CONSENSUS_INDEX}

# just save the fq file already converted
# ## transform all bam files into fastq format
# for i in ./*.bam; 
#     do samtools bam2fq $i > ${i%.bam}.fq; 
# done


## using BWA mem to align WGS reads to our consensus reference
bwa mem ${CONSENSUS_INDEX} ${FQ_INPUT} -K 100000000 -p -v 3 -Y > ${SAM_OUTPUT}
#rm ${FQ_INPUT}

## preparing aligned reads for variant calling
gatk AddOrReplaceReadGroups -I ${SAM_OUTPUT} -O ${temp_dir}${SAMPLE_ID}-addedReadGroup.sam -LB Pond -PL ILLUMINA -PU 0 -SM ${SAMPLE_ID}
samtools view -C -T ${CONSENSUS_REFERENCE} -o ${temp_dir}${SAMPLE_ID}-addedReadGroup.bam ${temp_dir}${SAMPLE_ID}-addedReadGroup.sam
samtools sort ${temp_dir}${SAMPLE_ID}-addedReadGroup.bam -o ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam
samtools index -b ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam
rm ${temp_dir}${SAMPLE_ID}-addedReadGroup.bam
rm ${temp_dir}${SAMPLE_ID}-addedReadGroup.sam
#rm ${SAM_OUTPUT}


## call the genetic variants
gatk Mutect2 -R ${CONSENSUS_REFERENCE} -L chrM \
--mitochondria-mode -I ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam \
-O ${vcf_dir}${SAMPLE_ID}_variants_called_against_consensus.vcf --min-base-quality-score 30
#rm ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam
#rm ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam.bai
