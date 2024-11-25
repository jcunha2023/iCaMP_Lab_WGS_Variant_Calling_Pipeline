#!/usr/bin/env python
# coding: utf-8

import sys
import pandas as pd



#import files
file = sys.argv[1]
sampid = sys.argv[2]
subjid = sys.argv[3]
output_file = sys.argv[4]
vcf_dir = "./vcf_files_rCRS/"

# Open the input file and extract the header

header_lines = []
with open(file, "r") as f:
    for line in f:
        if line.startswith("#"):
            header_lines.append(line)  # get header lines
        else:
            break

#filter by VAF
df = pd.read_csv(file, comment="#", sep="\t", header=None, 
                  names=["CHROM","POS","ID","REF","ALT","QUAL","FILTER","INFO","FORMAT","RESULT"])
df[["GT","AD","AF","DP","F1R2","F2R1","SB"]] = df["RESULT"].str.split(":",expand=True).iloc[:, : 7]
df["AF"] = pd.to_numeric(df["AF"])

#debug print statement
print(df.head())

filtered_df = df[df['AF'] > 0.5].copy()
filtered_df["SAMPID"] = sampid
filtered_df["SUBJID"] = subjid


with open(output_file, "w") as f:
    f.writelines(header_lines)  # Write the header lines to the output file
filtered_df.iloc[:, :10].to_csv(output_file, sep="\t", header=False, index=False, mode="a") 


