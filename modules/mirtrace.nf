#!/usr/bin/env nextflow
/**
* MIRTRACE QC MODULE
* 
* This module runs miRTrace QC on the input fastq files.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process MIRTRACE_QC {
    
    tag "${meta.id}"
    label "process_medium"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mirtrace:1.0.1--0':
        'biocontainers/mirtrace:1.0.1--0' }"

    // publishDir "${params.outdir}/mirtrace/${meta.id}/", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*report.html"), emit: html
    tuple val(meta), path("*results.json"), emit: json
    tuple val(meta), path("*log"), emit: log
    tuple val(meta), path("qc_passed_reads.all.uncollapsed/*.mirtrace.fa.gz"), emit: fasta

    script:
    def adapter = params.three_prime_adapter ? "-a ${params.three_prime_adapter}" : ''
    def title   = params.mirtrace_title ? "--title ${params.mirtrace_title}" : ''
    def comment = params.mirtrace_comment ? "--comment ${params.mirtrace_comment}" : ''
    """
    mv $reads ${meta.id}.fastq.gz

    mirtrace qc \\
        -s $params.mirtrace_species \\
        -p $params.mirtrace_protocol \\
        -t $task.cpus \\
        -o . \\
        $adapter \\
        $title \\
        $comment \\
        --verbosity-level 2 \\
        --force --write-fasta --uncollapse-fasta \\
        ${meta.id}.fastq.gz \\
        2> >(tee mirtrace.log >&2)

    mv qc_passed_reads.all.uncollapsed/*fasta qc_passed_reads.all.uncollapsed/${meta.id}.mirtrace.fa
    gzip qc_passed_reads.all.uncollapsed/${meta.id}.mirtrace.fa
    """
}