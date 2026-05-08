### iCamP Lab WGS Variant Calling Pipeline

Calling Mitochondrial Genetic Variants from WGS Data

Steps to run the pipeline:

1) Create and activate base conda environment.
```shell
conda env create -f ./envs/snakemake_base.yml
conda activate snakemake_base
```

2) Update values in config/config.yml for desired input and outputs.

3) Run the pipeline:
```shell
# Go to scripts directory
cd src

# Test that all of the file names are correct
# and get number of jobs that will be run
snakemake -s Snakefile --dry-run

# Run the pipeline using cluster-generic
snakemake -s Snakefile --executor cluster-generic --sdm conda \
--cluster-generic-submit-cmd "qsub -P icamp -pe omp {threads}" --jobs ### fill this in based on dry-run output ###
```
