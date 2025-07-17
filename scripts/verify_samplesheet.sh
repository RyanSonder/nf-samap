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

#==========================================================
# Main Logic
#==========================================================

## Enforce column order and existence
# - Read the header
echo ""
log "INFO" "Reading header from sample sheet"
read -r header < "$samplesheet" 

# - Check that the header matches expected columns
log "INFO" "Checking header columns"
if [[ "$header" == "id,matrix,fasta,annotation" ]]; then
    log "INFO" "Header matches expected format"
else
    log "ERROR" "Header does not match expected format: 'id,matrix,fasta,annotation'"
    exit 1
fi

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
log "INFO" "Checking data entries in sample sheet"
line_num=1
tail -n +2 "$samplesheet" | while IFS=, read -r id matrix fasta annotation; do 
    line_num=$((line_num + 1))

    # 1. Validate ID
    if [[ ! $id =~ ^[A-Za-z0-9_-]+$ ]]; then
        log "ERROR" "Line $line_num: Invalid id '$id' (only letters, digits, _ or - allowed)"
        exit 1
    fi

    # 2. Validate matrix
    if [[ ! $matrix =~ \.rds$ ]] && [[ ! $matrix =~ \.h5ad ]]; then
        log "ERROR" "Line $line_num: 'matrix' entry invalid '$matrix' (must end with .rds or .h5ad)"
        exit 1
    fi

    # 3. Validate fasta
    if [[ ! $fasta =~ \.fa(sta)?$ ]]; then
        log "ERROR" "Line $line_num: 'fasta' entry invalid '$fasta' (must end with .fa or .fasta)"
        exit 1
    fi

    # 4. Validate annotation
    if [[ -z $annotation ]]; then
        log "ERROR" "Line $line_num: 'annotation' entry is empty"
        exit 1
    fi
done
log "INFO" "All data entries validated successfully"

echo ""
log "INFO" "Sample sheet verification completed successfully"