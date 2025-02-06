#!/usr/bin/env nextflow
/**
* PREPARE MIRNA REFERENCE SUBWORKFLOW
* 
* This subworkflow runs bioawk to clean the mature miRNA reference and then
* creates a genome index using bowtie.
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
include { BIOAWK as CLEAN_MATURE } from '../modules/bioawk.nf'
include { BOWTIE_INDEX as MATURE_INDEX } from '../modules/bowtie_index.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PREPARE_MIRNA {

    take:
    val_mature   // file: /path/to/mature.fasta
    
    main:

    // Create channel from parameter
    ch_mature_ref = Channel.fromPath( val_mature, checkIfExists: true )
        .map{ it -> [ [id:it.baseName], it ] }.collect()
    
    // Clean mature miRNA reference
    ch_cleaned = CLEAN_MATURE( ch_mature_ref )
    
    // Create index
    MATURE_INDEX( ch_cleaned )
    
    emit:
    fasta = ch_cleaned.fasta         // channel: [ val(meta), path(fasta) ]
    index = MATURE_INDEX.out.index   // channel: [ val(meta), path(index) ]
}