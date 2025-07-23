/*
 *  MODULE: 01_ensure_h5ad.nf
 *
 *  Description: 
 *      Converts RDS file to H5AD if needed.
 *
 *  Inputs:
 *      run_id:         ID of the nextflow process
 *      sample_sheet:   Path to the sample sheet
 *      data_dir:       Directory containing RDS files
 *
 *  Outputs:
 *      A log file with the results of the conversion.
 *      The converted H5AD file.
 */

process ENSURE_H5AD {
    tag "${run_id} - ${sample_meta.id}: ensure h5ad"

    input:
        val run_id
        tuple val (sample_meta), path(matrix), path(fasta)

    output:
        path "*.log", emit: logfile
        // tuple val(sample_meta), path("${sample_meta.id}.h5ad"), emit: converted_matrix
        tuple val(sample_meta), path("${sample_meta.id}.h5ad"), path(fasta), emit: converted_meta
        path "${sample_meta.id}.h5ad", emit: h5ad_file

    script:
    """
    set -eou pipefail

    LOG="${run_id}_${sample_meta.id}_ensure_h5ad.log"

    matrix="${matrix}"
    id="${sample_meta.id}"

    tee -a "\$LOG" <<< "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Using matrix file '\${matrix}' with ID '\${id}'"
    
    if [[ "\$matrix" == *.rds ]]; then
        tee -a "\$LOG" <<< "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Converting RDS to H5AD for sample: \$id" > /dev/null
        rds_to_h5ad.R \\
            --rds "\$matrix" \\
            --out "\${id}" \\
            --ident "\${id}" \\
            2>&1 | tee -a "\$LOG" > /dev/null
        echo "\${id}.h5ad"
    elif [[ "\$matrix" == *.h5ad ]]; then
        tee -a "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Matrix is already in H5AD format: \$matrix" > /dev/null
        cp "\$matrix" "\${id}.h5ad"
        echo "\${id}.h5ad"
    else 
        tee -a "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [ERROR]: Unsupported file format for matrix: \$matrix" > /dev/null
        exit 65
    fi
    """
}
