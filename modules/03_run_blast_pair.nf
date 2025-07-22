/*
 *  MODULE: 03_run_blast_pair.nf
 *
 *  Description: 
 *      Uses bash script provided from 
 *      https://github.com/atarashansky/SAMap
 *      on pairs of samples.
 *
 *  Inputs:
 *      run_id:         Timestamp of the nextflow process
 *      val(a):         Map with keys: fasta, type, id2 (Sample A metadata)
 *      val(b):         Map with keys: fasta, type, id2 (Sample B metadata)
 *
 *  Outputs:
 *      Two BLAST result text files for each direction and a logfile
 *      {run_id}/maps/{pair_id}/[A_to_B.txt, B_to_A.txt]
 */

process RUN_BLAST_PAIR {
    tag "${run_id} - ${a.id2}_vs_${b.id2}"

    input:
        val run_id
        tuple val(a), val(b)
        path data_dir

    output:
        path "maps/*/*_to_*.txt", emit: maps
        path "*.log", emit: logfile

    script:
    """
    set -eou pipefail

    LOG="${run_id}_${a.id2}${b.id2}_blast.log"
        
    fasta_a=\$(basename "${a.fasta}")
    cp "${a.fasta}" "\${fasta_a}"
    fasta_b=\$(basename "${b.fasta}")
    cp "${b.fasta}" "\${fasta_b}"
    
    map_genes.sh \\
        --threads ${task.cpus} \\
        --tr1 "\${fasta_a}" --t1 ${a.type} --n1 ${a.id2} \\
        --tr2 "\${fasta_b}" --t2 ${b.type} --n2 ${b.id2} | \\
        while IFS= read -r line; do
            echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')] \$line"
        done 2>&1 | tee -a \$LOG
    """
}
