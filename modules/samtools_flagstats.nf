#!/usr/bin/env nextflow
/**
* SAMTOOLS FLAGSTATS MODULE
* 
* This module runs samtools flagstats to the resulting .bam files
* 
* @author Xavier Benedicto Molina
*
**/

process SAMTOOLS_FLAGSTATS {

    tag "${meta.id}"
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.flagstats"), emit: flagstats

    script:
    def rename_genome = task.ext.args ?: ''
    """
    samtools flagstats \\
        -@ $task.cpus \\
        $bam > ${meta.id}.flagstats

    $rename_genome
    """
}