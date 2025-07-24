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
        cat(sprintf("Unknown argument: %s", key))
        stop("Unknown argument: ", key)
    }
}

rds <- opt_list[["--rds"]]
out <- opt_list[["--out"]]
ident <- opt_list[["--ident"]]

if (!file.exists(rds)) {
    cat(sprintf("RDS file not found: %s", rds))
    stop("RDS not found: %s", rds)
} else {
    cat(sprintf("RDS file found"))
}

# ============================================================
# Load the RDS file and convert it to H5AD
# ============================================================

# - Load the RDS file
cat(sprintf("Loading RDS file: %s", rds))
so <- readRDS(rds)

# - Convert to V3 object (h5ad conversion does not work on V5)
cat(sprintf("Converting Seurat object to V3"))
so[["RNA3"]] <- as(so[["RNA"]], Class = "Assay")
DefaultAssay(so) <- "RNA3"
so[["RNA"]] <- NULL
so <- RenameAssays(so, RNA3 = "RNA")

# - Find list of barcodes
cat(sprintf("Getting list of barcodes from Seurat object"))
barcodes <- colnames(so)
cat(sprintf("Discovered %d barcodes", length(barcodes)))

# - Get the barcodes matching the sample ident
cat(sprintf("Selecting barcodes matching %s", ident))
bcs_subset <- grep(ident, barcodes, value = TRUE)
cat(sprintf("Selected %d barcodes", length(bcs_subset)))

# - Subset the Seurat object basted on the barcodes subset
cat(sprintf("Subsetting Seurat object based on selected barcodes"))
so_subset <- subset(so, cells = bcs_subset)

# - Save the Seurat object to h5Seurat format
cat(sprintf("Saving subset data to h5Seurat format: %s", out))
SaveH5Seurat(so_subset, filename = out, overwrite = TRUE)

# - Convert the h5Seurat file to h5ad format
cat(sprintf("Converting h5Seurat to h5ad format: %s", glue("{out}.h5seurat")))
Convert(glue("{out}.h5seurat"), dest = "h5ad", overwrite = TRUE)

cat(sprintf("Conversion complete. Output file: %s.h5ad", out))