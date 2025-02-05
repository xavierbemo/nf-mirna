#!/usr/bin/env nextflow
/**
* SAMTOOLS SORT MODULE
* 
* This module runs samtools to sort the resulting .bam files
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process SAMTOOLS_STATS {

    tag "${meta.id}"
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    // publishDir "${params.outdir}/bowtie_mature/${meta.id}", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.stats"), emit: stats

    script:
    def rename_genome = task.ext.args ?: ''
    """
    samtools stats \\
        -@ $task.cpus \\
        $bam > ${meta.id}.stats

    $rename_genome
    """
}