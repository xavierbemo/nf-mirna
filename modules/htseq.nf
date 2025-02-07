#!/usr/bin/env nextflow
/**
* HTSEQ-COUNT MODULE
* 
* This module runs htseq-count to quantify genome mapped reads.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process HTSEQ_COUNT {

    tag "${meta.id}"
    label "process_medium"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/htseq:2.0.5--py39hd5189a5_1' :
        'biocontainers/htseq:2.0.5--py311hc1104ee_3' }"

    publishDir "${params.outdir}/genome_quant/", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(bam), val(meta_gtf), path(gtf)

    output:
    tuple val(meta), path("*tsv"), emit: counts

    script:
    """
    echo "miRNA\tcounts" > ${meta.id}.genome.htseq.tsv
    
    htseq-count \\
        -t miRNA \\
        -f bam \\
        -s no \\
        -i Name \\
        -n $task.cpus \\
        $bam \\
        $gtf \\
        >> ${meta.id}.genome.htseq.tsv
    """
}