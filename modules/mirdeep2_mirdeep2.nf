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
    label "process_low"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mirdeep2:2.0.1.2--0':
        'biocontainers/mirdeep2:2.0.1.2--0' }"
    
    publishDir "${params.outdir}/mirdeep2/${meta.id}/", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(fasta) 
    tuple val(meta2), path(arf)
    tuple val(meta3), path(genome_fa)
    tuple val(meta4), path(mature_ref)
    tuple val(meta5), path(hairpin_ref)
    tuple val(meta6), path(other_ref)

    output:
    tuple val(meta), path("*_mirdeep2.log"), emit: log
    tuple val(meta), path("*_mirdeep2.bed"), emit: bed
    tuple val(meta), path("*_mirdeep2.csv"), emit: csv
    tuple val(meta), path("*_mirdeep2.html"), emit: html
    tuple val(meta), path("miRNAs_expressed_all_samples.csv"), emit: other
    tuple val(meta), path("*_mirdeep2_pdfs/*.pdf"), emit: pdf, optional: true

    script:
    // Evaluate other refs as in:
    // https://nextflow-io.github.io/patterns/optional-input/
    def other_ref_eval = other_ref.name != "NO_FILE" ? "${other_ref}" : 'none'
    def randfold       = params.mirdeep_randfold ? '' : '-c'
    def pdf_reports    = params.mirdeep_pdfs ? '' : '-d'
    def mirbase_v18    = params.mirdeep_mirbase_v18 ? '-P' : ''
    """
    miRDeep2.pl \\
        $fasta \\
        $genome_fa \\
        $arf \\
        $mature_ref \\
        $other_ref_eval \\
        $hairpin_ref \\
        $randfold \\
        $pdf_reports \\
        $mirbase_v18 \\
        -v \\
        2> >(tee ${meta.id}_mirdeep2.log >&2)

    mv miRNAs_expressed_all_samples*.csv miRNAs_expressed_all_samples.csv
    mv result_*.bed ${meta.id}_mirdeep2.bed
    mv result_*.csv ${meta.id}_mirdeep2.csv
    mv result_*.html ${meta.id}_mirdeep2.html


    if [[ -d \$(find . -name pdfs_* -type d) ]]; then
        mv pdfs_* ${meta.id}_mirdeep2_pdfs
    fi
    """ 
}