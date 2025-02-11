#Base image 
FROM condaforge/mambaforge:latest

#Set environment variables
ENV DEBIAN_FRONTEND=noninteractive 

#Define paths and directories 

ENV HOME_DIR=/mtDNA_variant_call_pipeline
ENV SCRIPTS_DIR=/mtDNA_variant_call_pipeline/src/
ENV BIN_DIR=/mtDNA_variant_call_pipeline/bin/
ENV INPUT_DIR=/mtDNA_variant_call_pipeline/input_bams/
ENV CONFIG_DIR=/mtDNA_variant_call_pipeline/config
ENV rCRS_OUTPUT_DIR=/mtDNA_variant_call_pipeline/vcf_files_rCRS/
ENV CONSENSUS_OUTPUT_DIR=/mtDNA_variant_call_pipeline/vcf_files_consensus/

ENV PATH="$SCRIPTS_DIR:$BIN_DIR:$PATH"

#Update and install necessary packages
RUN apt-get -y update && \
    apt-get install -y bash wget tar nano curl git bzip2 && \
    git --version 

# Configure conda timeout and mirror settings
RUN echo "channels:\n  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/conda-forge/\n  - bioconda\n  - defaults\nssl_verify: true\ntimeout: 120" > /opt/conda/.condarc

#Copy config directory and environment yml files into image
COPY config/ $CONFIG_DIR

#Copy directory with chrM reference into image
COPY chrM_reference/ $HOME_DIR/chrM_reference

#Copy snakemake pipeline and scripts directory into image
COPY src/ $SCRIPTS_DIR

# Create base snakemake environment
RUN conda env remove -n snakemake_env || true && \
    mamba env create -f $CONFIG_DIR/snakemake_base_ENV.yml && \
    mamba clean --all -y

# Add mamba to conda environment
RUN conda install mamba -c conda-forge

# Activate environment upon container startup
RUN echo "conda run -n snakemake_env" >> ~/.bashrc
ENV PATH /opt/conda/envs/snakemake_env/bin:$PATH

#Set working directory
WORKDIR $HOME_DIR

#old script below. uncomment to revert.


# #Copy snakemake pipeline and scripts directory into image
# COPY Snakefile $HOME_DIR/Snakefile
# COPY scripts/ $SCRIPTS_DIR

# #Set working directory
# WORKDIR $HOME_DIR

# #Make RUN commands use the new environment:
# #SHELL ["conda", "run", "-n", "snakemake_base", "/bin/bash", "-c"]

# #Define entry point for the container and command to activate the base environment

# # ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "snakemake_base"]