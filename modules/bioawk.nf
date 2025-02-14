#!/usr/bin/env nextflow
/**
* BIOAWK MODULE
* 
* This module runs bioawk to clean input fasta references.
* 
* @author Xavier Benedicto Molina
*
**/

process BIOAWK {

    tag "${meta.id}"
    label "process_single"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--h5bf99c6_6':
        'biocontainers/bioawk:1.0--h5bf99c6_6' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.clean.fa"), emit: fasta

    script:
    def args = task.ext.args ?: "print \">\"\$name\"\\n\"\$seq}'"
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
        $args \\
        \$FASTA > \${FASTA}.clean

    mv \${FASTA}.clean \$(basename \${FASTA} .fa).clean.fa  
    """
}