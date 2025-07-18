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
 *
 *  Outputs:
 *      A pickled SAM object
 *      A log file containing the output of the script
 */

process LOAD_SAM {
    tag "${run_id} - ${meta_ch.id} load and pickle SAM objects"

    input:
        val run_id
        val meta_ch
        path data_dir 

    output:
        path "*.pkl", emit: sam
        path "*.log", emit: logfile

    script:
    """
    set -euo pipefail

    LOG="${run_id}_${meta_ch.id}_load_sams.log"

    chmod +x /usr/local/bin/load_sam.py

    load_sam.py \\
        --id2 "${meta_ch.id2}" \\
        --h5ad "${meta_ch.matrix}" 2>&1 | tee -a \$LOG
    """
}