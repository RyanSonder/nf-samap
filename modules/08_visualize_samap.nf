/*
 *  MODULE: 08_visualize_samap.nf
 *
 *  Description: 
 *      Produces several visualizations from analysis.py from 
 *      https://github.com/atarashansky/SAMap
 *
 *  Inputs:
 *      run_id:         Timestamp of the nextflow process
 *      samap_object:   Channel containing a pickled SAMAP object
 *      sample_sheet:   Path to the sample sheet CSV with sample metadata
 *
 *  Outputs:
 *      Several visualizations about the SAMap results and a logfile
 *      results/${run_di}/plots/chord.html
 *      results/${run_id}/plots/sankey.html
 *      results/${run_id}/plots/scatter.png
 *      results/${run_id}/csv/hms.csv 
 *      results/${run_id}/csv/pms.csv 
 */

process VISUALIZE_SAMAP {
    tag "${run_id} - SAMap visualization"

    container 'pipeline/samap:latest'

    input:
        val run_id
        path samap_obj
        val meta_str

    output:
        path "chord.html"
        path "sankey.html"
        path "scatter.png"
        path "hms.csv"
        path "pms.csv"
        path "*.log"

    script:
    """
    set -euo pipefail

    chmod +x /usr/local/bin/visualize_samap.py

    LOG="${run_id}_viz.log"

    echo "${meta_str}" 

    visualize_samap.py \\
        --input "${samap_obj}" \\
        --meta "${meta_str}" 2>&1 | tee -a \$LOG
    """
}
