#!/usr/bin/env nextflow
/**
* BIOAWK MODULE
* 
* This module runs bioawk to clean input fasta references.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process BIOAWK {

    tag "${meta.id}"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--h5bf99c6_6':
        'biocontainers/bioawk:1.0--h5bf99c6_6' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_clean.fa"), emit: fasta

    script:
    """
    if [[ ${fasta} == *.gz ]]; then
        gunzip -k $fasta
        FASTA=\$( basename $fasta .gz )
    else
        FASTA=$fasta
    fi

    bioawk -c fastx '{
        gsub(\"U\", \"T\", \$seq); 
        gsub(/[^ATGCatgc]/, \"N\", \$seq); 
        sub(/ .*/, \"\", \$name); 
        if (\$name ~ /^hsa/) print \">\"\$name\"\\n\"\$seq}' \\
        \$FASTA > \${FASTA}.clean

    mv \${FASTA}.clean \$(basename \${FASTA} .fa)_clean.fa  
    """

}