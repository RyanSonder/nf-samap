#!/usr/bin/env Rscript

# rds_to_h5ad.R
# Author : Ryan Sonderman
# Date   : 2025-07-15
# Version: 1.0.0
# Purpose: RDS to H5AD conversion for SAMap


#— print a full stack trace on error
options(error = function() {
  traceback()
  quit(status = 1)
})

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
    "--ident"   = NA
)

for(i in seq(1, length(args), by=2)) {
    key <- args[i]
    val <- args[i+1]
    if (key %in% names(opt_list)) {
        opt_list[[key]] <- val
    } else {
        sprintf("Unknown argument: %s\n", key)
        stop("Unknown argument: ", key)
    }
}

rds <- opt_list[["--rds"]]
out <- opt_list[["--out"]]
ident <- opt_list[["--ident"]]

if (!file.exists(rds)) {
    sprintf("RDS file not found: %s\n", rds)
    stop("RDS not found: %s", rds)
} else {
    sprintf("RDS file found")
}

# ============================================================
# Load the RDS file and convert it to H5AD
# ============================================================

# - Load the RDS file
sprintf("Loading RDS file: %s\n", rds)
so <- readRDS(rds)

# - Convert to V3 object (h5ad conversion does not work on V5)
sprintf("Converting Seurat object to V3\n")
so[["RNA3"]] <- as(so[["RNA"]], Class = "Assay")
DefaultAssay(so) <- "RNA3"
so[["RNA"]] <- NULL
so <- RenameAssays(so, RNA3 = "RNA")

# - Find list of barcodes
sprintf("Getting list of barcodes from Seurat object\n")
barcodes <- colnames(so)
sprintf("Discovered %d barcodes\n", length(barcodes))

# - Get the barcodes matching the sample ident
sprintf("Selecting barcodes matching %s\n", ident)
bcs_subset <- grep(ident, barcodes, value = TRUE)
sprintf("Selected %d barcodes\n", length(bcs_subset))

# - Subset the Seurat object basted on the barcodes subset
sprintf("Subsetting Seurat object based on selected barcodes\n")
so_subset <- subset(so, cells = bcs_subset)

# - Save the Seurat object to h5Seurat format
sprintf("Saving subset data to h5Seurat format: %s\n", out)
SaveH5Seurat(so_subset, filename = out, overwrite = TRUE)

# - Convert the h5Seurat file to h5ad format
sprintf("Converting h5Seurat to h5ad format: %s\n", glue("{out}.h5seurat"))
Convert(glue("{out}.h5seurat"), dest = "h5ad", overwrite = TRUE)

sprintf("Conversion complete. Output file: %s.h5ad\n", out)