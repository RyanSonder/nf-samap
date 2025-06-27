/*
 *  MODULE: preprocess.nf
 *
 *  Description: 
 *      Updates the sample sheet to add:
 *          - [type] Classification of fasta (protein or nucleotide)
 *          - [id2] Unique 2-character ID
 *
 *  Inputs:
 *      run_id:         Timestamp of the nextflow process
 *      sample_sheet:   Path to the sample sheet being updated
 *      data_dir:       Staging the data directory so the script can access it
 *
 *  Outputs:
 *      A sample sheet with the added values and a logfile
 *      {run_id}_sample_sheet.csv
 *      {run_id}_preprocess.log
 */

process PREPROCESS {
    tag "${run_id} - sample sheet preprocessing"

    input:
        val run_id
        path sample_sheet
        path data_dir

    output:       
        path "*.csv", emit: sample_sheet_pr
        path "*.log", emit: logfile

    script:
    """
    LOG=${run_id}_preprocess.log
    update_sample_sheet.sh ${sample_sheet} ${run_id}_${sample_sheet} 2>&1 | tee -a \$LOG
    """
}
