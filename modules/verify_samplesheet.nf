/*
 *  MODULE: verify_samplesheet.nf
 *
 *  Description: 
 *      Verifies the sample sheet is in the expected format
 *      and contains the required columns.
 *
 *  Inputs:
 *      run_id:         ID of the nextflow process
 *      sample_sheet:   Path to the sample sheet
 *
 *  Outputs:
 *      A log file with the results of the verification.
 */

process VERIFY_SAMPLESHEET {
    tag "${run_id} - verify sample sheet"

    container "${params.container_blast}"

    input:
        val run_id
        path sample_sheet

    output:
        path "*.log", emit: logfile

    script:
    """
    set -euo pipefail

    LOG="${run_id}_verify_samplesheet.log"
    chmod +x /usr/local/bin/verify_samplesheet.sh
    verify_samplesheet.sh ${sample_sheet} 2>&1 | tee -a \$LOG
    """
}