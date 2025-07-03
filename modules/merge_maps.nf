/*
 *  MODULE merge_maps.nf 
 *
 *  Description:
 *      Combines the channel of BLAST mappings
 *      into a single directory to be passed along
 *
 *  Inputs:
 *      maps_dirs:      A list of paths to each BLAST mapping
 * 
 *  Outputs:
 *      A single directory `maps/` containing the file structure
 *      necessary to run SAMap
*/

process MERGE_MAPS {
    tag "${run_id} - merge blast mappings"

    input:
        val run_id
        val maps_dirs

    output:
        path "maps/", emit: maps
        path "*.log", emit: logfile

    script:
    """
    LOG="${run_id}_merge.log"
    echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')] Creating unified `maps/` directory"
    mkdir -p maps
    for d in ${maps_dirs.join(' ')}; do
        pair_id_dir=\$(basename \$(find \$d -type d -mindepth 1 -maxdepth 1))
        echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')]   Attempting to copy \${pair_id_dir} into `maps/`"
        mkdir -p maps/\$pair_id_dir
        cp \$d/\$pair_id_dir/*_to_*.txt maps/\$pair_id_dir/
    done 2>&1 | tee -a \$LOG
    """
}
