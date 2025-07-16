/*
 *  MODULE: rds_to_h5ad.nf
 *
 *  Description: 
 *      Converts RDS file to H5AD in the format SAMap expects.
 *
 *  Inputs:
//  *      run_id:         Timestamp of the nextflow process
 *
 *  Outputs:
//  *      Two BLAST result text files for each direction and a logfile
 */

process RDS_TO_H5AD {
    tag "${run_id} - rds to h5ad"

    input:
        val run_id
        path sample_sheet


    output:
        // path "maps/*/*_to_*.txt", emit: maps
        path "*.log", emit: logfile

    script:
    """
    LOG="${run_id}_convert.log"
    tail -n +2 "$sample_sheet" | while IFS=, read -r id rds; do
        echo "FUCKYOUFUCKYOUFUCKYOU"
    done
    """
}
