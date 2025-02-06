# mtDNA_variant_calling_pipeline

Nathaniel Fisher
September 2024

WGS Variant Calling Pipeline, Version 1

This is a pipeline to call mitochondrial variants from WGS data initially developed by Ariel Xu.

The pipeline consists of the following steps:
1. Input an aligned WGS bam files which is subsetted to only contain reads aligning to chrM (ideally this file also removes NUMT associated reads).
2. Convert this bam to fastq format for first round of alignment.
3. Align to rCRS sequence using BWA mem.
4. Run first round of variant calling using Gatk4 Mutect2.
5. Filter vcf outputs for variants with VAF > 0.5.
6. Build a consensus reference chrM sequence using filtered vcf and rCRS reference with bcftools consensus for each sample.
7. Repeat the variant calling with this consensus reference: align fq to consensus reference, run second round of variant calling.
8. Split multiallelic sites.

Instuctions for running the pipeline:
1. Copy the directory to your working directory:
'''
cp -r ./copy_contents_of_this_directory/* $DESTINATION_DIRECTORY
'''
2. Create and activate base conda environment.
'''
conda env create -f ./envs/snakemake_base_ENV.yml
conda activate snakemake_base_ENV
'''
3. Add your bam files to samples directory.
(would probably be easier to change ./input_bams to current location of your bam files if you have a lot of files.
In order to do this change input file paths in scripts - I can add this for the next version)
'''
cp $BAM_SOURCE_DIR/*.bam ./input_bams
'''
4) Run the pipeline:
'''
#  Test that all of the file names are correct
#  and get number of jobs that will be run
snakemake -s NUMT_pipeline_v1.snake --dry-run
# Run the pipeline using cluster-generic
snakemake -s NUMT_pipeline_v1.snake --executor cluster-generic --use-conda \
--cluster-generic-submit-cmd "qsub -P icamp -pe omp {threads}" --jobs ### fill this in based on dry-run output ###
