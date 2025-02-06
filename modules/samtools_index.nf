#!/usr/bin/env nextflow
/**
* SAMTOOLS IDXSTATS MODULE
* 
* This module runs samtools index to create the .bam indices (.bai) 
*
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process SAMTOOLS_INDEX {

    tag "${meta.id}"
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai

    script:
    """
    samtools index \\
        -@ $task.cpus \\
        $bam \\
        -o ${meta.id}.bam.bai
    """
}
