#!/usr/bin/env python
# coding: utf-8

import sys
import pandas as pd

# Input arguments
file = sys.argv[1]
sampid = sys.argv[2]
subjid = sys.argv[3]
refseq_type = sys.argv[4]
vcf_dir = "./vcf_files_rCRS/"

print(f"Processing file: {file}")
print(f"Sample ID: {sampid}, Subject ID: {subjid}, Reference Type: {refseq_type}")

# Read the input VCF file (skip header lines)
try:
    df = pd.read_csv(file, comment="#", sep="\t", header=None, 
                     names=["CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "RESULT"])
    print(f"File loaded successfully. Total rows: {df.shape[0]}")
except Exception as e:
    print(f"Error reading file: {e}")
    sys.exit(1)

# Check the first few rows for sanity
print("First 5 rows of input data:")
print(df.head())

# Split "RESULT" column and extract VAF
try:
    df[["GT", "AD", "VAF", "DP", "F1R2", "F2R1", "SB"]] = df["RESULT"].str.split(":", expand=True).iloc[:, :7]
    df["VAF"] = pd.to_numeric(df["VAF"], errors="coerce")
    print("VAF column extracted successfully.")
except Exception as e:
    print(f"Error processing RESULT column: {e}")
    sys.exit(1)

# Debug: Check the distribution of VAF values
print("VAF distribution:")
print(df["VAF"].describe())

# Filter variants with VAF > 0.5
filtered_df = df[df["VAF"] > 0.5]
print(f"Filtered rows with VAF > 0.5: {filtered_df.shape[0]}")

if filtered_df.empty:
    print(f"No variants passed the filter for sample {sampid}. Exiting.")
    sys.exit(0)

# Prepare output
filtered_df["SAMPID"] = sampid
filtered_df["SUBJID"] = subjid
out_df = filtered_df.iloc[:, :10]

# Write to file
output_path = f"{vcf_dir}{sampid}_variants_called_against_rCRS_splitted_filtered_{refseq_type}.vcf"
try:
    out_df.to_csv(output_path, sep="\t", header=False, index=False, mode="a")
    print(f"Filtered variants written to: {output_path}")
except Exception as e:
    print(f"Error writing to file: {e}")
    sys.exit(1)
