#Base image 
FROM ubuntu:23.04

#Set environment variables
ENV DEBIAN_FRONTEND=noninteractive 

#Define paths and directories 

ENV HOME_DIR=/mtDNA_variant_call_pipeline/
ENV SCRIPTS_DIR=/mtDNA_variant_call_pipeline/scripts/
ENV BIN_DIR=/mtDNA_variant_call_pipeline/bin/
ENV INPUT_DIR=/mtDNA_variant_call_pipeline/input_bams
ENV rCRS_OUTPUT_DIR=/mtDNA_variant_call_pipeline/vcf_files_rCRS/
ENV CONSENSUS_OUTPUT_DIR=/mtDNA_variant_call_pipeline/vcf_files_consensus/

ENV PATH="$SCRIPTS_DIR:$BIN_DIR:$PATH"

#Update and install necessary packages
RUN apt-get -y update && \
    apt-get install -y wget tar nano curl git bzip2 

#Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy

#Add conda to PATH variable
ENV PATH="/opt/conda/bin:$PATH"

#Install snakemake and snakemake wrapper utilities
RUN conda install -c bioconda snakemake && \
    pip install snakemake-wrapper-utils

#Copy snakemake pipeline, yml files, and scripts into container
COPY variant_calling_pipeline.snake $HOME_DIR/variant_calling_pipeline.snake
COPY scripts/ $SCRIPTS_DIR
COPY envs/ $HOME_DIR/envs

#Set working directory
WORKDIR $HOME_DIR

#Define entry point for the container
ENTRYPOINT ["snakemake", "--snakefile", "variant_calling_pipeline.snake", "--use-conda"]

