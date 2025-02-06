#!/usr/bin/env nextflow
/**
* MIRDEEP2 MODULE
* 
* This module runs miRDeep2.pl from miRDeep2 to discover novel miRNAs.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process MIRDEEP2_MIRDEEP2 {

    tag "${meta.id}"
    label "process_single"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mirdeep2:2.0.1.2--0':
        'biocontainers/mirdeep2:2.0.1.2--0' }"
    
    publishDir "${params.outdir}/mirdeep2/${meta.id}", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(fasta) 
    tuple val(meta2), path(arf)
    tuple val(meta3), path(genome_fa)
    tuple val(meta4), path(mature_ref)
    tuple val(meta5), path(hairpin_ref)

    output:
    // tuple val(meta), path("result*.{bed,csv,html}"), emit: outputs
    tuple val(meta), path("*_mirdeep2.log"), emit: log
    tuple val(meta), path("*_mirdeep2.bed"), emit: bed
    tuple val(meta), path("*_mirdeep2.csv"), emit: csv
    tuple val(meta), path("*_mirdeep2.html"), emit: html
    tuple val(meta), path("miRNAs_expressed_all_samples.csv"), emit: other

    script:
    """
    miRDeep2.pl \\
        $fasta \\
        $genome_fa \\
        $arf \\
        $mature_ref \\
        "none" \\
        $hairpin_ref \\
        -v -d -P \\
        2> >(tee ${meta.id}_mirdeep2.log >&2)

    mv miRNAs_expressed_all_samples*.csv miRNAs_expressed_all_samples.csv
    mv result_*.bed ${meta.id}_mirdeep2.bed
    mv result_*.csv ${meta.id}_mirdeep2.csv
    mv result_*.html ${meta.id}_mirdeep2.html
    """ 
}