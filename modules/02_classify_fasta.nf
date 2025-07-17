/*
 *  MODULE: classify_fasta.nf
 *
 *  Description: 
 *      Classifies a .fasta file as either protein 
 *      or nuceotide
 *
 *  Inputs:
 *      run_id:         ID of the nextflow process
 *      sample_sheet:   Path to the sample sheet
 *      data_dir:       Directory containing fasta files
 *
 *  Outputs:
 *      A log file with the results of the classification.
 *      A new dictionary with the type classification
 */

process CLASSIFY_FASTA {
    tag "${run_id} - ${sample_meta.id} classify fasta"

    input:
        val run_id
        val sample_meta
        path data_dir

    output:
        path "*.log", emit: logfile
        tuple val(sample_meta), stdout, emit: classified_sample

    script:
    """
    set -eou pipefail

    LOG="${run_id}_${sample_meta.id}_classify.log"

    fasta="${sample_meta.fasta}"
    tee -a "\$LOG" <<< "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Found fasta: \${fasta}" > /dev/null
    
    line=\$(grep -v '^>' "\$fasta" | head -n 1)
    tee -a "\$LOG" <<< "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Checking line..." > /dev/null

    if [[ "\$line" =~ ^[ACGTUNacgtun]+\$ ]]; then
        tee -a "\$LOG" <<< "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Classifying fasta as nucleotide for sample: ${sample_meta.id}" > /dev/null
        echo "nucl"
    else
        tee -a "\$LOG" <<< "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Classifying fasta as protein for sample: ${sample_meta.id}" > /dev/null
        echo "prot"
    fi
    """
}
