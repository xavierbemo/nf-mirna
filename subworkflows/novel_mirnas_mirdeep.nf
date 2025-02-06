#!/usr/bin/env nextflow
/**
* DISCOVERY OF NOVEL miRNAs WITH MIRDEEP2 SUBWORKFLOW
* 
* This subworkflow cleans the resulting reads from the miRTrace QC step,
* maps them to the reference genome and then uses miRDeep2 to discover novel miRNAs.
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
include { BIOAWK as CLEAN_FASTA } from '../modules/bioawk.nf'
include { BIOAWK as CLEAN_HAIRPIN } from '../modules/bioawk.nf'
include { BIOAWK as CLEAN_GENOME } from '../modules/bioawk.nf'
include { MIRDEEP2_MAPPER } from '../modules/mirdeep2_mapper.nf'
include { MIRDEEP2_MIRDEEP2 } from '../modules/mirdeep2_mirdeep2.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NOVEL_MIRNA {

    take:
    ch_mirtrace_fasta   // channel: [ val(meta), path(reads) ]
    ch_genome_index     // channel: [ val(index_meta), path(index) ]
    ch_mature_ref       // channel: [ val(meta), path(fasta) ]
    val_genome          // file:    /path/to/genome.fa
    val_hairpin         // file:    /path/to/hairpin.fa

    main:

    // Prepare and clean miRNA hairpin reference
    ch_hairpin = Channel.fromPath( val_hairpin, checkIfExists: true )
        .map{ it -> [ [id:it.baseName], it ] }.collect()
    ch_hairpin_ref = CLEAN_HAIRPIN( ch_hairpin )

    // Prepare and clean genome reference
    ch_genome = Channel.fromPath( val_genome, checkIfExists: true )
        .map{ it -> [ [id:it.baseName], it ] }.collect()
    ch_genome_ref = CLEAN_GENOME( ch_genome )
    
    // Clean reads
    ch_cleaned_reads = CLEAN_FASTA( ch_mirtrace_fasta )

    // Map reads
    ch_mirdeep_input = ch_cleaned_reads.combine( ch_genome_index )
    MIRDEEP2_MAPPER( ch_mirdeep_input )
    ch_mirdeep_fasta = MIRDEEP2_MAPPER.out.fasta
    ch_mirdeep_arf = MIRDEEP2_MAPPER.out.arf
    
    // miRDeep2 module
    MIRDEEP2_MIRDEEP2( 
        ch_mirdeep_fasta, 
        ch_mirdeep_arf, 
        ch_genome_ref, 
        ch_mature_ref, 
        ch_hairpin_ref 
    )

    emit:
    arf   = MIRDEEP2_MAPPER.out.arf     // channel: [ val(meta), path(arf) ]
    fasta = MIRDEEP2_MAPPER.out.fasta   // channel: [ val(meta), path(fasta) ]
    bed   = MIRDEEP2_MIRDEEP2.out.bed   // channel: [ val(meta), path(bed) ]
    csv   = MIRDEEP2_MIRDEEP2.out.csv   // channel: [ val(meta), path(csv) ]
    html  = MIRDEEP2_MIRDEEP2.out.html  // channel: [ val(meta), path(html) ]  
}
