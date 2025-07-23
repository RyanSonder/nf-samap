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
    tag "${run_id} - ${metaA.id2}_vs_${metaB.id2}"

    input:
        val run_id
        tuple val(metaA), path(matA), path(fasA, stageAs: 'A/*'), 
              val(metaB), path(matB), path(fasB, stageAs: 'B/*')

    output:
        path "maps/*/*_to_*.txt", emit: maps
        path "*.log", emit: logfile

    script:
    """
    set -eou pipefail

    LOG="${run_id}_${metaA.id2}${metaB.id2}_blast.log"
        
    fasta_a=\$(basename "${fasA}")
    cp "${fasA}" "\${fasta_a}"
    fasta_b=\$(basename "${fasB}")
    cp "${fasB}" "\${fasta_b}"
    
    map_genes.sh \\
        --threads ${task.cpus} \\
        --tr1 "\${fasta_a}" --t1 ${metaA.type} --n1 ${metaA.id2} \\
        --tr2 "\${fasta_b}" --t2 ${metaB.type} --n2 ${metaB.id2} | \\
        while IFS= read -r line; do
            echo "[\$(date +'%Y-%m-%d %H:%M:%S.%3N')] \$line"
        done 2>&1 | tee -a \$LOG
    """
}
