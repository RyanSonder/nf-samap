/*
 *  MODULE: ensure_h5ad.nf
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
    tag "${run_id} - ensure h5ad"

    input:
        val run_id
        val sample_meta
        path data_dir

    output:
        path "*.log", emit: logfile
        path "${sample_meta.id}.h5ad", emit: h5ad_file

    script:
    """
    set -eou pipefail

    LOG="${run_id}_${sample_meta.id}_ensure_h5ad.log"

    chmod +x /usr/local/bin/rds_to_h5ad.R

    matrix="${sample_meta.matrix}"
    id="${sample_meta.id}"

    if [[ "\$matrix" == *.rds ]]; then
        echo "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Converting RDS to H5AD for sample: \$id" | tee -a \$LOG
        rds_to_h5ad.R \\
            --rds "\$matrix" \\
            --out "\${id}" \\
            --ident "\${id}" \\
            --meta_field "orig.ident" 2>&1 | tee -a \$LOG
    elif [[ "\$matrix" == *.h5ad ]]; then
        echo "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [INFO]: Matrix is already in H5AD format: \$matrix" | tee -a \$LOG
        cp "\$matrix" "\${id}.h5ad"
    else 
        echo "\$(date +'%Y-%m-%d %H:%M:%S.%3N') [ERROR]: Unsupported file format for matrix: \$matrix" | tee -a \$LOF
        exit 1
    fi
    """
}
