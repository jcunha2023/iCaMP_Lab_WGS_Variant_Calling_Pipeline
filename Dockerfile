#Base image 
FROM ubuntu:23.04

#Set environment variables
ENV DEBIAN_FRONTEND=noninteractive 

#Define paths and directories 

ENV HOME_DIR=/mtDNA_variant_call_pipeline/
ENV SCRIPTS_DIR=/mtDNA_variant_call_pipeline/scripts/
ENV BIN_DIR=/mtDNA_variant_call_pipeline/bin/
ENV INPUT_DIR=/mtDNA_variant_call_pipeline/input_bams/
ENV CONFIG_DIR=/mtDNA_variant_call_pipeline/config
ENV rCRS_OUTPUT_DIR=/mtDNA_variant_call_pipeline/vcf_files_rCRS/
ENV CONSENSUS_OUTPUT_DIR=/mtDNA_variant_call_pipeline/vcf_files_consensus/

ENV PATH="$SCRIPTS_DIR:$BIN_DIR:$PATH"

#Update and install necessary packages
RUN apt-get -y update && \
    apt-get install -y wget tar nano curl git bzip2 && \
    git --version 



#Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh 
RUN bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    echo "export PATH=/opt/conda/bin:$PATH" > /etc/profile.d/conda.sh
#Add conda to PATH variable
ENV PATH="/opt/conda/bin:$PATH"


# Create snakemake environment and install snakemake and mamba
RUN conda create -n snakemake_env python=3.8 -y && \
    /opt/conda/bin/conda install -c conda-forge mamba -y && \
    /opt/conda/bin/mamba install -n snakemake_env -c conda-forge -c bioconda -c defaults snakemake pandas -y && \
    /opt/conda/bin/mamba run -n snakemake_env pip install snakemake-wrapper-utils

# RUN conda install -n base -c conda-forge mamba -y && \
#     mamba create -n snakemake_env -c conda-forge -c bioconda snakemake pandas -y && \
#     conda clean --all


#Copy snakemake pipeline, yml files, and scripts into container
COPY variant_calling_pipeline.snake $HOME_DIR/variant_calling_pipeline.snake
COPY scripts/ $SCRIPTS_DIR
COPY config/ $CONFIG_DIR
COPY config/samtools_ENV.yml $CONFIG_DIR/samtools_ENV.yml


#Set working directory
WORKDIR $HOME_DIR

#Define entry point for the container
ENTRYPOINT ["/opt/conda/envs/snakemake_env/bin/snakemake", "--snakefile", "variant_calling_pipeline.snake", "--use-conda"]
CMD ["--snakefile", "variant_calling_pipeline.snake", "--use-conda"]
