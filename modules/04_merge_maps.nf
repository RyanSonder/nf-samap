/*
 *  MODULE 04_merge_maps.nf 
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
        path maps_dirs

    output:
        path "maps/", emit: maps
        path "*.log", emit: logfile

    script:
    """
    LOG="${run_id}_merge.log"
    echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')] Creating unified maps/ directory" | tee -a \$LOG
    mkdir -p maps
    for map in ${maps_dirs}; do
        echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')]   Identified \$map mapping, creating dir"
        mkdir -p maps/\$map
        echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')]   Attempting to copy \${map} into maps/"
        cp \$map/*_to_*.txt maps/\$map/
    done 2>&1 | tee -a \$LOG
    echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')] Script complete" | tee -a \$LOG
    """
}
