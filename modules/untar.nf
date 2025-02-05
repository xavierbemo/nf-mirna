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
    
    tag "${index_path.baseName}"
    label "process_single"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(index_path)

    output:
    tuple val(meta), path("bowtie_index"), emit: untar

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir bowtie_index

    if [[ \$(tar -taf ${index_path} | grep -o -P "^.*?\\/" | uniq | wc -l) -eq 1 ]]; then
        tar \\
            -xazvf \\
            $index_path \\
            -C bowtie_index \\
            --strip-components 1
    else
        tar \\
            -xazvf \\
            $index_path \\
            -C bowtie_index
    fi
    """
}