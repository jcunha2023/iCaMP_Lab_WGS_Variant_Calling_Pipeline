#Base image 
FROM condaforge/mambaforge:latest

#Set environment variables
ENV DEBIAN_FRONTEND=noninteractive 

#Define paths and directories 

ENV HOME_DIR=/mtDNA_variant_call_pipeline
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



# #Install Miniconda
# RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh 
# RUN bash /tmp/miniconda.sh -b -p /opt/conda && \
#     rm /tmp/miniconda.sh && \
#     echo "export PATH=/opt/conda/bin:$PATH" > /etc/profile.d/conda.sh
# #Add conda to PATH variable
# ENV PATH="/opt/conda/bin:$PATH"

#Copy config directory and environment yml files into image
COPY config/ $CONFIG_DIR

# Create base snakemake environment
RUN mamba env create -f $CONFIG_DIR/snakemake_base_ENV.yml && \
    mamba clean --all -y


# #Retrieve conda environments, install them
# RUN mamba env create --prefix /conda-envs/0e63127d95f487eff6aa743bdaf2d592 --file $CONFIG_DIR/samtools_ENV.yml && \
#     mamba clean --all -y

#Copy snakemake pipeline and scripts directory into image
COPY Snakefile $HOME_DIR/Snakefile
COPY scripts/ $SCRIPTS_DIR

#Set working directory
WORKDIR $HOME_DIR

#Define entry point for the container

ENTRYPOINT ["conda", "run", "-n", "snakemake_base", "snakemake"]
#CMD ["--snakefile", "Snakefile", "--sdm", "conda", "--verbose"]

CMD ["--snakefile", "Snakefile", "--sdm", "conda", "--dryrun", "-p"]
