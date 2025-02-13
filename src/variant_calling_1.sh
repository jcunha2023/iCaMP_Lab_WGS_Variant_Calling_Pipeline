#!/bin/bash


INPUT_SAM=$1
REFERENCE=$2
INTERVAL=$3
WORKDIR=$4

temp_dir=${WORKDIR}/tmp/
vcf_dir=${WORKDIR}/vcf_files_rCRS/

# Make the temp directory
mkdir -p "$temp_dir"

# get sample id
SAMPLE_ID_TEMP="${INPUT_SAM##*/}"
SAMPLE_ID="${SAMPLE_ID_TEMP%%_*}"

# preparing alignmed reads for variant calling
gatk AddOrReplaceReadGroups -I $INPUT_SAM -O ${temp_dir}${SAMPLE_ID}-addedReadGroup.sam -LB Pond -PL ILLUMINA -PU 0 -SM ${SAMPLE_ID}
samtools view -@ 1 -C -T $REFERENCE -o ${temp_dir}${SAMPLE_ID}-addedReadGroup.bam ${temp_dir}${SAMPLE_ID}-addedReadGroup.sam
samtools sort -@ 1 ${temp_dir}${SAMPLE_ID}-addedReadGroup.bam -o ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam
samtools index -@ 1 -b ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam
rm ${temp_dir}${SAMPLE_ID}-addedReadGroup.bam
rm ${temp_dir}${SAMPLE_ID}-addedReadGroup.sam
rm $INPUT_SAM

# # variant calling round 1
gatk Mutect2 -R $REFERENCE -L $INTERVAL --mitochondria-mode -I ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam \
-O ${vcf_dir}${SAMPLE_ID}_variants_called_against_rCRS.vcf --min-base-quality-score 30
rm ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam
rm ${temp_dir}${SAMPLE_ID}-addedReadGroup-sorted.bam.bai
