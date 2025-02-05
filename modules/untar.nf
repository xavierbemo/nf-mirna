#!/usr/bin/env nextflow
/**
* UNTAR MODULE
* 
* This module decompresses any tar.gz file. 
* Adapted from nf-core/smrnaseq UNTAR module.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process UNTAR {
    
    tag "${archive}"
    label "process_single"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(archive)

    output:
    tuple val(meta), path("$prefix"), emit: untar

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: ( meta.id ? "${meta.id}" : 
        archive.baseName.toString().replaceFirst(/\.tar.gz$/, ""))
    """
    mkdir $prefix

    if [[ \$(tar -taf ${archive} | grep -o -P "^.*?\\/" | uniq | wc -l) -eq 1 ]]; then
        tar \\
            -C $prefix --strip-components 1 \\
            -xavf \\
            $archive

    else
        tar \\
            -C $prefix \\
            -xavf \\
            $archive
    fi
    """
}