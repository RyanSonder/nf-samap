/*
 *  MODULE: 07_run_samap.nf
 *
 *  Description: 
 *      Runs the SAMap algorithm on a SAMAP object
 *
 *  Inputs:
 *      run_id:         Timestamp of the nextflow process
 *      samap_object:   Channel containing a pickled SAMAP object
 *
 *  Outputs:
 *      A pickled SAMAP object and a logfile
 *      results/run_id/samap_objects/samap_results.pkl
 *      results/run_dir/logs/run_id_run_samap.log
 */

process RUN_SAMAP {
    tag "${run_id} - run SAMap"

    input:
        val run_id
        path samap_object

    output:
        path "samap_results.pkl", emit: results
        path "*.log", emit: logfile

    script:
    """
    set -euo pipefail

    chmod +x /usr/local/bin/run_samap.py

    LOG=${run_id}_run_samap.log

    run_samap.py \\
        -i ${samap_object} \\
        --name "samap_results.pkl" 2>&1 | tee -a \$LOG
    """
}
