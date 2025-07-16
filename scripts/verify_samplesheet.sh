#!/bin/bash
set -euo pipefail
#==========================================================
# Author: Ryan Sonderman
# Date: 2025-07-16
# Version: 1.1.0
# Description: This script reads a sample sheet CSV and 
#              verifies its format.
# Dependencies: None
# Usage: ./verify_samplesheet.sh <samplesheet>
#==========================================================

# Standardized logging
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    echo "$timestamp [$level]: $message"
}


#==========================================================
# Variable Initialization
#==========================================================
samplesheet=""

# Parse command-line arguments
if [ $# -ne 1 ]; then
    log "ERROR" "Usage: $0 <sample_sheet>"
    exit 1
fi
samplesheet="$1"
if [ ! -f "$samplesheet" ]; then
    log "ERROR" "File '$samplesheet' not found or not readable"
    exit 2
fi
log "INFO" "Found sample sheet: $samplesheet"

EXPECTED_COLS=("id" "h5ad" "rds" "fasta" "annotation")
REQUIRED_COLS=("id" "fasta" "annotation")
data_paths=( "fasta" )


#==========================================================
# Helper Functions
#==========================================================

# Function to check if a column exists in the header
column_exists() {
    local col="$1"
    if [[ "$header" != *"$col"* ]]; then 
        log "ERROR" "Missing '$col' column in samplesheet" 
        exit 1
    fi
}


#==========================================================
# Main Logic
#==========================================================

## CHECK THE COLUMN HEADERS
# - Read the header
log "INFO" "Reading header from sample sheet"
read -r header < "$samplesheet"

# - Ensure required columns exist
echo ""
log "INFO" "Checking columns in sample sheet"
log "INFO" "Checking for required columns: '${REQUIRED_COLS[*]}'"
for col in "${REQUIRED_COLS[@]}"; do
    column_exists "$col"
done
log "INFO" "All required columns found in sample sheet"

# - h5ad or rds column is required
log "INFO" "Checking for 'h5ad' or 'rds' column in sample sheet" 
if [[ "$header" == *"h5ad"* ]] || [[ "$header" == *"rds"* ]]; then
    if [[ "$header" == *"h5ad"* ]] && [[ "$header" == *"rds"* ]]; then
        log "WARNING" "Both 'h5ad' and 'rds' columns found. Using 'h5ad' for processing. Ignoring 'rds'"
        data_paths+=( "h5ad" )
    else
        if [[ "$header" == *"h5ad"* ]]; then
            log "INFO" "Found 'h5ad' column in samplesheet"
            data_paths+=( "h5ad" )
        else
            log "INFO" "Using 'rds' column in samplesheet"
            data_paths+=( "rds" )
        fi
    fi
else
    log "ERROR" "Missing 'h5ad' or 'rds' column in sample sheet"
    exit 1
fi

# - Ensure no unexpected columns are present
echo ""
log "INFO" "Checking for unexpected columns in sample sheet"
IFS=',' read -r -a header_cols <<< "$header"
for col in "${header_cols[@]}"; do
    # shellcheck disable=SC2076
    if [[ ! " ${EXPECTED_COLS[*]} " =~ " $col " ]]; then
        log "ERROR" "Unexpected column '$col' found in sample sheet"
        exit 1
    fi
done
log "INFO" "No unexpected columns found in sample sheet"


## CHECK THE DATA ENTRIES
# - Ensure a minimum of two rows of data are present
echo ""
log "INFO" "Checking for minimum data rows in sample sheet"
data_rows=$(wc -l < "$samplesheet")
if [ "$data_rows" -lt 2 ]; then
    log "ERROR" "Sample sheet must contain at least three rows (header + two data rows)"
    exit 1
fi
log "INFO" "Minimum data rows check passed. Found $data_rows rows in sample sheet"

# - Ensure all entries are populated and valid
echo ""
log "INFO" "Checking for valid entries in sample sheet"
line_num=1
IFS=, read -r -a headers <<< "$header"
cols="${headers[*]}"
# shellcheck disable=SC2229
# shellcheck disable=SC2086
tail -n +2 "$samplesheet" | while IFS=, read -r $cols; do
    line_num=$((line_num + 1))

    # 1. Validate ID
    # shellcheck disable=SC2154
    if [[ ! $id =~ ^[A-Za-z0-9_-]+$ ]]; then
        log "ERROR" "Line $line_num: Invalid id '$id' (only letters, digits, _ or - allowed)"
        exit 1
    fi

    # 2. Validate data paths
    for path in "${data_paths[@]}"; do
        if [[ -z "${!path}" ]]; then
            log "ERROR" "Line $line_num: Missing '$path' entry"
            exit 1
        fi
        if [[ ! -f "${!path}" ]]; then
            log "ERROR" "Line $line_num: File '${!path}' does not exist or is not readable"
            exit 1
        fi
    done

    # 3. Validate annotation
    if [[ -z "$annotation" ]]; then 
        log "ERROR" "Line $line_num: Missing 'annotation' entry"
        exit 1
    fi
done
log "INFO" "All entries in sample sheet are valid"

echo ""
log "INFO" "Sample sheet verification completed successfully"