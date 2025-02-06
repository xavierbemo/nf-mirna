#!/usr/bin/env nextflow
/**
* BOWTIE INDEX MODULE
* 
* This module runs bowtie-index on the input fasta files.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process BOWTIE_INDEX {

    tag "${meta.id}"
    label "process_single"
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bowtie:1.3.0--py38hed8969a_1' :
        'biocontainers/bowtie:1.3.0--py38hed8969a_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("bowtie"), emit: index

    script:
    """
    mkdir -p bowtie
    
    bowtie-build \\
        $fasta \\
        bowtie/$fasta.baseName
    """
}