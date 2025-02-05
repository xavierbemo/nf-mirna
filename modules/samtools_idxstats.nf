#!/usr/bin/env nextflow
/**
* SAMTOOLS IDXSTATS MODULE
* 
* This module runs samtools idxstats to quantify the resulting .bam files
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process SAMTOOLS_IDXSTATS {

    tag "${meta.id}"
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    publishDir "${params.outdir}/mirna_quant/", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*mature.idxstats.tsv"), emit: idxstats

    script:
    """
    samtools index \\
        -@ $task.cpus \\
        $bam
    
    echo "mirna\tlength\tmapped_reads\tunmapped_reads" \\
        > ${meta.id}.idxstats.tsv
    
    samtools idxstats \\
        $bam \\
        >> ${meta.id}.mature.idxstats.tsv

    rm *bai
    """
}