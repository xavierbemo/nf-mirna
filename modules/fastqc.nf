#!/usr/bin/env nextflow
/**
* FASTQC MODULE
* 
* This module runs FastQC on the input fastq files.
* Adapted from nf-core/smrnaseq
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/


process FASTQC {

    tag "${meta.id}"
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

    publishDir "${params.outdir}/fastqc/${meta.id}/", mode: 'copy', overwrite: true
    
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"), emit: zip

    script:
    // The total amount of allocated RAM by FastQC is equal to the number of threads defined (--threads) time the amount of RAM defined (--memory)
    // https://github.com/s-andrews/FastQC/blob/1faeea0412093224d7f6a07f777fad60a5650795/fastqc#L211-L222
    // Dividing the task.memory by task.cpu allows to stick to requested amount of RAM in the label
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB') / task.cpus
    // FastQC memory value allowed range (100 - 10000)
    def fastqc_memory = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    """
    mv $reads ${meta.id}.fastq.gz
    
    fastqc \\
        --threads $task.cpus \\
        --memory $fastqc_memory \\
        ${meta.id}.fastq.gz
    """
}