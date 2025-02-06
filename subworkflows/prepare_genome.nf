#!/usr/bin/env nextflow
/**
* PREPARE GENOME MODULE
* 
* This subworkflow [...]
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
include { UNTAR } from '../modules/untar.nf'
include { BOWTIE_INDEX as GENOME_INDEX } from '../modules/bowtie_index.nf'
include { BIOAWK as CLEAN_GENOME } from '../modules/bioawk.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PREPARE_GENOME {

    take:
    val_genome          // file: /path/to/genome.fasta
    val_genome_index    // file or directory: /path/to/bowtie/ or /path/to/bowtie.tar.gz

    main:

    // Prepare and clean genome reference
    ch_genome = Channel.fromPath( val_genome, checkIfExists: true )
            .map{ it -> [ [id:it.baseName], it ] }.collect()
    
    ch_genome_ref = CLEAN_GENOME( ch_genome )

    // If no genome index is provided, generate a new index from the genome file
    if ( !val_genome_index ) { 
        
        GENOME_INDEX( ch_genome )
        ch_genome_index = GENOME_INDEX.out.index
    
    // If the index is a tar.gz file, handle it like a compressed archive
    } else if ( val_genome_index && val_genome_index.endsWith(".tar.gz") ) {
        
        ch_genome_index = Channel.fromPath( val_genome_index, checkIfExists: true )
            .map{ it -> 
                def id = it.baseName.toString().replaceFirst(/\.tar(\.gz)?$/, "")
                return [[id:id], it] 
            }.collect()
        
        UNTAR( ch_genome_index )
        
        ch_genome_index = UNTAR.out.untar
            .map{ meta, index_dir ->
                def index_prefix = extractFirstIndexPrefix(index_dir)
                return [[id:index_prefix], index_dir]
            }
    
    // If the index is a directory (not compressed), process the files inside it directly
    } else {
        
        ch_genome_index = Channel.fromPath( val_genome_index, checkIfExists: true, type: 'dir' )
            .map{ index_dir ->
                // List the files inside the directory
                def files = index_dir.listFiles()
                if (files == null || files.length == 0) {
                    throw new Exception("The provided Bowtie index directory is empty or doesn't exist: ${index_dir}")
                }
                // Extract the prefix from the files
                def index_prefix = extractFirstIndexPrefix(index_dir)
                return [[id:index_prefix], index_dir]
            }
    }

    emit:
    genome_ref  = ch_genome_ref     // channel: [ val(meta), path(genome) ] 
    index       = ch_genome_index   // channel: [ val(meta), path(index) ]
}

// Extract prefix from Bowtie index files
def extractFirstIndexPrefix(files_path) {
    def files = files_path.listFiles()
    if (files == null || files.length == 0) {
        throw new Exception("The provided bowtie_index path doesn't contain any files.")
    }
    def index_prefix = ''
    for (file_path in files) {
        def file_name = file_path.getName()
        // Look for Bowtie index files with the ".1.ebwt" suffix (the first file in the index)
        if (file_name.endsWith(".1.ebwt") && !file_name.endsWith(".rev.1.ebwt")) {
            index_prefix = file_name.substring(0, file_name.lastIndexOf(".1.ebwt"))
            break
        }
    }
    if (index_prefix == '') {
        throw new Exception("Unable to extract the prefix from the Bowtie index files. No file with the '.1.ebwt' extension was found. Please ensure that the correct files are in the specified path.")
    }
    return index_prefix
}
