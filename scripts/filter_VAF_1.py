#!/usr/bin/env python
# coding: utf-8

import sys
import pandas as pd



#import files
file = sys.argv[1]
sampid = sys.argv[2]
subjid = sys.argv[3]
vcf_dir = "./vcf_files_rCRS/"

#filter by VAF
df = pd.read_csv(file, comment="#", sep="\t", header=None, 
                  names=["CHROM","POS","ID","REF","ALT","QUAL","FILTER","INFO","FORMAT","RESULT"])
df[["GT","AD","AF","DP","F1R2","F2R1","SB"]] = df["RESULT"].str.split(":",expand=True).iloc[:, : 7]
df["AF"] = pd.to_numeric(df["AF"])
filtered_df = df[df['AF'] > 0.5]
filtered_df["SAMPID"] = sampid
filtered_df["SUBJID"] = subjid
out_df = filtered_df.iloc[:, : 10]

#output file
out_df.to_csv(vcf_dir + sampid + '_variants_called_against_rCRS_splitted_filtered_lin.vcf', sep = '\t',header=False, index=False, mode="a")

