#!/usr/bin/env nextflow
/**
* MIRDEEP2 MAPPER MODULE
* 
* This module runs mapper.pl from miRDeep2.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process MIRDEEP2_MAPPER {

    tag "${meta.id}"
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mirdeep2:2.0.1.3--hdfd78af_2':
        'biocontainers/mirdeep2:2.0.1.3--hdfd78af_2' }"

    // publishDir "${params.outdir}/mirdeep2/${meta.id}", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads), val(index_meta), path(index)

    output:
    tuple val(meta), path("*.arf"), emit: arf
    tuple val(meta), path("*.genome.mirdeep.fa"), emit: fasta

    script:
    """
    INDEX_PREFIX=\$(find -L . -name "*.3.ebwt" | sed 's/\\.3.ebwt\$//')

    mapper.pl \\
        $reads \\
        -c -j -m -v \\
        -o $task.cpus \\
        -p \$INDEX_PREFIX \\
        -s ${meta.id}.genome.mirdeep.fa \\
        -t ${meta.id}.genome.mirdeep.arf
    """
}