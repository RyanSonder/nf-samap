/*
 *  MODULE: 05_load_sam.nf
 *
 *  Description: 
 *      Loads a SAM object using an h5ad file
 *
 *  Inputs:
 *      run_id:         Timestamp of the nextflow process
 *      meta_ch:        Channel containing metadata for the sample
 *      data_dir:       Staging the data directory so the script can access it
 *      h5ad_files:     Path to the h5ad files containing the SAM objects
 *
 *  Outputs:
 *      A pickled SAM object
 *      A log file containing the output of the script
 */

process LOAD_SAM {
    tag "${run_id} - ${sample_meta.id} load and pickle SAM objects"

    input:
        val run_id
        tuple val(sample_meta), path(matrix), path(fasta)

    output:
        path "*.pkl", emit: sam
        path "*.log", emit: logfile

    script:
    """
    set -euo pipefail

    LOG="${run_id}_${sample_meta.id}_load_sams.log"

    load_sam.py \\
        --id2 "${sample_meta.id2}" \\
        --h5ad "${matrix}" 2>&1 | tee -a \$LOG
    """
}