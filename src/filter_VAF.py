#!/usr/bin/env python
# coding: utf-8

import os
import sys
import pandas as pd

# Input arguments
file = sys.argv[1]  # Input VCF
sampid = sys.argv[2]  # Sample ID
subjid = sys.argv[3]  # Subject ID
output_file = sys.argv[4]  # Full path to the output VCF file


# Check if input file exists
if not os.path.exists(file):
    print(f"Error: Input file {file} does not exist.")
    sys.exit(1)

# Extract VCF header
header_lines = []
with open(file, "r") as f:
    for line in f:
        if line.startswith("#"):
            header_lines.append(line)
        else:
            break

# Load VCF data into dataframe
try:
    df = pd.read_csv(file, comment="#", sep="\t", header=None,
                     names=["CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "RESULT"])
except Exception as e:
    print(f"Error reading VCF file: {e}")
    sys.exit(1)

# Split RESULT column and filter based on VAF > 0.5
try:
    df[["GT", "AD", "AF", "DP", "F1R2", "F2R1", "SB"]] = df["RESULT"].str.split(":", expand=True).iloc[:, :7]
    df["AF"] = pd.to_numeric(df["AF"], errors="coerce")
    filtered_df = df[df['AF'] > 0.5].copy()
except Exception as e:
    print(f"Error processing VCF data: {e}")
    sys.exit(1)

# Add metadata columns
filtered_df["SAMPID"] = sampid
filtered_df["SUBJID"] = subjid


# Write header and data to a VCF file
try:
    with open(output_file, "w") as f:
        f.writelines(header_lines)
    filtered_df.iloc[:, :10].to_csv(output_file, sep="\t", header=False, index=False, mode="a")
    print(f"Filtered VCF written to: {output_file}")
except Exception as e:
    print(f"Error writing output file: {e}")
    sys.exit(1)

