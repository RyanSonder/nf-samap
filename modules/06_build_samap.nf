/*
 *  MODULE: 06_build_samap.nf
 *
 *  Description: 
 *      Creates a SAMAP object from blast mappings and SAM objects
 *
 *  Inputs:
 *      run_id:         Timestamp of the nextflow process
 *      sams_list:      List of paths to SAM objects
 *      maps_dir:       Directory containing the BLAST mappings
 *      data_dir:       Staging the data directory so the script can access it
 *
 *  Outputs:
 *      A pickled SAMAP object and a logfile.
 *      results/run_id/samap_objects/run_id_samap.pkl
 *      results/run_id/logs/run_id_build_samap.log
 */

process BUILD_SAMAP {
    tag "${run_id} - build SAMAP object"

    input:
        val run_id
        val sams_list
        path maps_dir
        path data_dir

    output:
        path "samap.pkl", emit: samap
        path "*.log", emit: logfile

    script:
    """
    set -euo pipefail

    LOG="${run_id}_build_samap.log"

    chmod +x /usr/local/bin/build_samap.py

    build_samap.py \\
        --sams "${sams_list}" \\
        --maps "${maps_dir}" \\
        --name "${run_id}_samap.pkl" | tee -a \$LOG
    """
}