#!/usr/bin/env nextflow
/**
* MULTIQC MODULE
* 
* This module runs multiqc across the pipeline.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/

process MULTIQC {

    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.27--pyhdfd78af_0' :
        'biocontainers/multiqc:1.27--pyhdfd78af_0' }"

    publishDir "${params.outdir}/multiqc/", mode: 'copy', overwrite: true

    input:
    path multiqc_files, stageAs: "?/*"
    path multiqc_config

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data

    when:
    task.ext.when == null || task.ext.when

    script:
    def config = multiqc_config ? "--config $multiqc_config" : ''
    """
    multiqc \\
        --force \\
        $config \\
        .
    """
}