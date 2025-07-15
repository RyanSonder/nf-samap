#!/usr/bin/env Rscript

# rds_to_h5ad.nf
# Author : Ryan Sonderman
# Date   : 2025-07-15
# Version: 1.0.0
# Purpose: RDS to H5AD conversion for SAMap

# ============================================================
# Load in the required libraries
# ============================================================

library(glue)
library(Seurat)
library(SeuratDisk)
library(SeuratObject)

# ============================================================
# Parse the command-line arguments
# ============================================================

args <- commandArgs(trailingOnly = TRUE)
opt_list <- list(
    "--rds"     = NA,
    "--out"     = NA,
    "--type"    = NA,
    "--ident"   = NA,
    "--meta_field" = NA
)

for(i in seq(1, length(args), by=2)) {
    key <- args[i]
    val <- args[i+1]
    if (key %in% names(opt_list)) {
        opt_list[[key]] <- val
    } else {
        stop("Unknown argument: ", key)
    }
}

rds <- opt_list[["--rds"]]
out <- opt_list[["--out"]]
type <- opt_list[["--type"]]
ident <- opt_list[["--ident"]]
meta_field <- opt_list[["--meta_field"]]

if (!file.exists(rds)) {
    stop("RDS not found: ", rds)
}

# ============================================================
# Load the RDS file and convert it to H5AD
# ============================================================

# - Load the RDS file
rds_data <- readRDS(rds)

# - Take the subset of the RDS data based on the identity
subset_data <- rds_data[, rds_data@meta.data[[ meta_field ]] == ident ]

# - Save the Seurat object to h5Seurat format
SaveH5Seurat(subset_data, filename = out)

# - Convert the h5Seurat file to h5ad format
Convert(glue("{out}.h5seurat"), dest = "h5ad")

