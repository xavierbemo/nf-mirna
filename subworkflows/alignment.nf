#!/usr/bin/env nextflow
/**
* miRNA QUANTIFICATION MODULE
* 
* This subworkflow runs miRTrace QC to filter the reads and then 
* aligns them agaisnt the mature miRNA reference.
* 
* @author Xavier Benedicto Molina
* @version 1.0
*
**/
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { BOWTIE_ALIGN } from '../modules/bowtie_alignment.nf'
include { SAMTOOLS_STATS } from '../modules/samtools_stats.nf'
include { SAMTOOLS_FLAGSTATS } from '../modules/samtools_flagstats.nf'
// include { SAMTOOLS_SORT } from '../modules/samtools_sort.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow ALIGNMENT {

    take:
    ch_reads   // channel: [ val(meta), path(reads) ]
    ch_index   // channel: [ val(meta), path(index) ]
    
    main:
    ch_reads_ref = ch_reads.combine( ch_index )
    
    // Alignment using Bowtie 1
    ch_alignment = BOWTIE_ALIGN( ch_reads_ref )
    
    // DEPRECATED: bam files are sorted during the bowtie alignment
    // ch_sorted = SAMTOOLS_SORT( ch_alignment.bam )
    
    // Get alignment stats
    SAMTOOLS_STATS( ch_alignment.bam )
    SAMTOOLS_FLAGSTATS( ch_alignment.bam )

    emit:
    bam         = ch_alignment.bam                  // channel: [ val(meta), path(bam) ]
    fasta       = ch_alignment.fasta                // channel: [ val(meta), path(fasta) ]
    out         = ch_alignment.out                  // channel: [ val(meta), path(out) ]
    stats       = SAMTOOLS_STATS.out.stats          // channel: [ val(meta), path(stats) ]
    flagstats   = SAMTOOLS_FLAGSTATS.out.flagstats  // channel: [ val(meta), path(flagstats) ]
}
