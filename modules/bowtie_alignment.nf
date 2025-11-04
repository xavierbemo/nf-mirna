#!/usr/bin/env nextflow
/**
* BOWTIE ALIGNMENT MODULE
* 
* This module runs bowtie to align the resulting miRTrace filtered
* reads agaisnt the mature miRNA reference.
* 
* @author Xavier Benedicto Molina
*
**/

process BOWTIE_ALIGN {

    tag "${meta.id}"
    label "process_medium"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ffbf83a6b0ab6ec567a336cf349b80637135bca3:c84c7c55c45af231883d9ff4fe706ac44c479c36-0' :
        'biocontainers/mulled-v2-ffbf83a6b0ab6ec567a336cf349b80637135bca3:c84c7c55c45af231883d9ff4fe706ac44c479c36-0' }"

    // publishDir "${params.outdir}/bowtie_mature/${meta.id}", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads), val(index_meta), path(mature_index)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.out"), emit: out
    tuple val(meta), path("${meta.id}_unaligned*.fa.gz"), emit: fasta, optional: true

    script:
    def args            = task.ext.args ?: ''
    def unaligned       = task.ext.args2 ?: ''
    def rename_genome   = task.ext.args3 ?: ''
    """
    INDEX_PREFIX=\$(find -L . -name "*.3.ebwt" | sed 's/\\.3.ebwt\$//')
    bowtie \\
        $args \\
        --threads $task.cpus \\
        --sam \\
        -x \$INDEX_PREFIX \\
        -f $reads \\
        $unaligned \\
        2> >(tee ${meta.id}.out >&2) \\
        | samtools view -@ $task.cpus -bS -o ${meta.id}.bam - 
    
    samtools sort \\
        -@ $task.cpus \\
        -o ${meta.id}.bam \\
        ${meta.id}.bam 

    gzip *.fa
    
    $rename_genome
    """
}