#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-mirna
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/xavierbemo/nf-mirna
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { UTILS_NFSCHEMA_PLUGIN } from './modules/local/utils_nfschema_plugin.nf'
include { samplesheetToList } from 'plugin/nf-schema'
include { PREPARE_MIRNA } from './subworkflows/prepare_mirna.nf'
include { PREPARE_GENOME } from './subworkflows/prepare_genome.nf'
include { FASTQC } from './modules/fastqc.nf'
include { MIRTRACE_QC } from './modules/mirtrace.nf'
include { ALIGNMENT as MATURE_ALIGNMENT } from './subworkflows/alignment.nf'
include { ALIGNMENT as GENOME_ALIGNMENT } from './subworkflows/alignment.nf'
include { SAMTOOLS_INDEX } from './modules/samtools_index.nf'
include { SAMTOOLS_IDXSTATS as MATURE_COUNTS } from './modules/samtools_idxstats.nf'
include { HTSEQ_COUNT as GENOME_COUNTS } from './modules/htseq.nf'
include { NOVEL_MIRNA } from './subworkflows/novel_mirnas_mirdeep.nf'
include { MULTIQC } from './modules/multiqc.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow {
    
    main:

    UTILS_NFSCHEMA_PLUGIN( workflow, params.validate_params, "${projectDir}/nextflow_schema.json" )

    if ( params.validate_params ) { validateInputParameters() }
    
    // Read samplesheet and create a tuple with sample_id and fastq file
    ch_samplesheet = Channel
        .fromList( samplesheetToList(params.input, "${projectDir}/assets/schema_input.json") )
        .map {
            meta, fastq_1, fastq_2 ->
                if (!fastq_2) {
                    return [ meta.id, meta + [ single_end:true ], [ fastq_1 ] ]
                } else {
                    return [ meta.id, meta + [ single_end:false ], [ fastq_1, fastq_2 ] ]
                }
        }
        .groupTuple()
        .map { samplesheet ->
            validateInputSamplesheet(samplesheet)
        }
        .map {
            meta, fastqs ->
                return [ meta, fastqs.flatten() ]
        }

    // Clean mature miRNA reference and create index
    PREPARE_MIRNA( params.mature )
    
    ch_mature_ref = PREPARE_MIRNA.out.fasta
    ch_mature_index = PREPARE_MIRNA.out.index

    // Prepare or create genome index
    if ( !params.skip_genome || !params.skip_mirdeep ) {
        
        PREPARE_GENOME( params.genome, params.genome_index )
        
        ch_genome_ref = PREPARE_GENOME.out.genome_ref
        ch_genome_index = PREPARE_GENOME.out.index
    }

    // FastQC process using the meta (sample_id) and FASTQ file
    if ( !params.skip_fastqc ) {
        FASTQC( ch_samplesheet )
    }

    // miRTrace QC process using the meta (sample_id) and FASTQ file
    ch_mirtrace = MIRTRACE_QC( ch_samplesheet )

    // Mature miRNA alignment and quantification
    ch_mature_alignment = MATURE_ALIGNMENT( ch_mirtrace.fasta, ch_mature_index )
    MATURE_COUNTS( ch_mature_alignment.bam )

    // Genome alignment using unmapped reads from mature miRNA alignment
    if ( !params.skip_genome ) {
        
        ch_mirna_gtf = Channel.fromPath( params.mirna_gtf, checkIfExists: true )
            .map{ gtf ->
                  def prefix = gtf.baseName 
                  return [[id:prefix], gtf]  
            }
        
        GENOME_ALIGNMENT( ch_mature_alignment.fasta, ch_genome_index )
        
        ch_genome_counts = GENOME_ALIGNMENT.out.bam.combine( ch_mirna_gtf ) 
        GENOME_COUNTS( ch_genome_counts )
    }

    // miRDeep2 module
    if ( !params.skip_mirdeep ) {
        NOVEL_MIRNA( 
            ch_mirtrace.fasta, 
            ch_genome_ref, 
            ch_genome_index, 
            ch_mature_ref, 
            params.hairpin 
        )
    }

    // MultiQC module
    if ( !params.skip_multiqc ) {

        ch_multiqc_config  = Channel
            .fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
        
        ch_multiqc_files = Channel.empty()

        if ( !params.skip_fastqc ) {
            ch_multiqc_files = FASTQC.out.zip.map { it[1] ?: [] }
        }
        ch_multiqc_files = ch_multiqc_files.mix( MIRTRACE_QC.out.html.map { it[1] ?: [] } )
        ch_multiqc_files = ch_multiqc_files.mix( MIRTRACE_QC.out.json.map { it[1] ?: [] } )
        ch_multiqc_files = ch_multiqc_files.mix( MIRTRACE_QC.out.log.map { it[1] ?: [] } )
        ch_multiqc_files = ch_multiqc_files.mix( MATURE_ALIGNMENT.out.out.map { it[1] ?: [] } )
        ch_multiqc_files = ch_multiqc_files.mix( MATURE_ALIGNMENT.out.stats.map { it[1] ?: [] } )
        ch_multiqc_files = ch_multiqc_files.mix( MATURE_ALIGNMENT.out.flagstats.map { it[1] ?: [] } )
        
        if ( !params.skip_genome ) {
            ch_multiqc_files = ch_multiqc_files.mix( GENOME_ALIGNMENT.out.out.map { it[1] ?: [] } )
            ch_multiqc_files = ch_multiqc_files.mix( GENOME_ALIGNMENT.out.stats.map { it[1] ?: [] } )
            ch_multiqc_files = ch_multiqc_files.mix( GENOME_ALIGNMENT.out.flagstats.map { it[1] ?: [] } )
        }
        MULTIQC( ch_multiqc_files.collect(), ch_multiqc_config )
    }

    workflow.onComplete { completionSummary() }
    workflow.onError { log.error "Pipeline failed." }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Check and validate pipeline parameters
//
def validateInputParameters() {

    if ( !params.mirtrace_species ) {
        error("Reference species for miRTrace is not defined via the `--mirtrace_species` parameter.")
    }
    if ( !params.mature ) {
        error("Mature miRNA fasta file not found. Please specify using the `--mature` parameter.")
    }
    if ( !params.skip_genome && !params.skip_mirdeep && !params.genome_index && !params.genome ) {
        error("No genome index or FASTA was provided. Please either specify a path to a genome index or a genome FASTA file or skip the genome alignment with `--skip_genome true`.")
    }
    if ( !params.skip_genome && !params.mirna_gtf ) {
        error("No miRNA GTF file was provided. Please either specify a path to a GTF file or skip the genome alignment with `--skip_genome true`.")
    }
    if ( !params.skip_mirdeep && !params.hairpin ) {
        error("No hairpin miRNA fasta file was provided. Please either specify a path to a hairpin miRNA FASTA file or skip the miRDeep2 module with `--skip_mirdeep true`.")
    }
    if ( !params.skip_mirdeep && !params.genome ) {
        error("No genome FASTA file was provided. Please either specify a path to a genome FASTA file or skip the miRDeep2 module with `--skip_mirdeep true`.")
    }
}

// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    def (metas, fastqs) = input[1..2]

    // Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
    def endedness_ok = metas.collect{ meta -> meta.single_end }.unique().size == 1
    if (!endedness_ok) {
        error("Please check input samplesheet -> Multiple runs of a sample must be of the same datatype i.e. single-end or paired-end: ${metas[0].id}")
    }

    // Emit a warning if `single_end` is false
    if (metas[0].single_end == false) {
        log.warn "Sample ${metas[0].id} is detected as paired-end reads (fastq_1 and fastq_2). The pipeline only handles SE data. Samplesheets with fastq_1 and fastq_2 are supported but fastq_2 is removed."
        // Remove fastq_2 from the list and keep only fastq_1
        fastqs = fastqs.collect { it.take(1) }
        metas[0].single_end = true
    }

    return [ metas[0], fastqs ]
}

// Print pipeline summary on completion
//
def completionSummary(monochrome_logs=false) {
    def colors = logColours(monochrome_logs) as Map
    if (workflow.success) {
        if (workflow.stats.ignoredCount == 0) {
            log.info("\n${colors.purple}[${workflow.manifest.name}]${colors.green} Pipeline completed successfully${colors.reset}")
        }
        else {
            log.info("\n${colors.purple}[${workflow.manifest.name}]${colors.yellow} Pipeline completed successfully, but with errored process(es) ${colors.reset}")
        }
    }
    else {
        log.info("\n${colors.purple}[${workflow.manifest.name}]${colors.red} Pipeline completed with errors${colors.reset}")
    }
}

// ANSII colours used for terminal logging
//
def logColours(monochrome_logs=true) {
    def colorcodes = [:] as Map

    // Reset / Meta
    colorcodes['reset']      = monochrome_logs ? '' : "\033[0m"
    colorcodes['bold']       = monochrome_logs ? '' : "\033[1m"
    colorcodes['dim']        = monochrome_logs ? '' : "\033[2m"
    colorcodes['underlined'] = monochrome_logs ? '' : "\033[4m"
    colorcodes['blink']      = monochrome_logs ? '' : "\033[5m"
    colorcodes['reverse']    = monochrome_logs ? '' : "\033[7m"
    colorcodes['hidden']     = monochrome_logs ? '' : "\033[8m"

    // Regular Colors
    colorcodes['black']  = monochrome_logs ? '' : "\033[0;30m"
    colorcodes['red']    = monochrome_logs ? '' : "\033[0;31m"
    colorcodes['green']  = monochrome_logs ? '' : "\033[0;32m"
    colorcodes['yellow'] = monochrome_logs ? '' : "\033[0;33m"
    colorcodes['blue']   = monochrome_logs ? '' : "\033[0;34m"
    colorcodes['purple'] = monochrome_logs ? '' : "\033[0;35m"
    colorcodes['cyan']   = monochrome_logs ? '' : "\033[0;36m"
    colorcodes['white']  = monochrome_logs ? '' : "\033[0;37m"

    // Bold
    colorcodes['bblack']  = monochrome_logs ? '' : "\033[1;30m"
    colorcodes['bred']    = monochrome_logs ? '' : "\033[1;31m"
    colorcodes['bgreen']  = monochrome_logs ? '' : "\033[1;32m"
    colorcodes['byellow'] = monochrome_logs ? '' : "\033[1;33m"
    colorcodes['bblue']   = monochrome_logs ? '' : "\033[1;34m"
    colorcodes['bpurple'] = monochrome_logs ? '' : "\033[1;35m"
    colorcodes['bcyan']   = monochrome_logs ? '' : "\033[1;36m"
    colorcodes['bwhite']  = monochrome_logs ? '' : "\033[1;37m"

    // Underline
    colorcodes['ublack']  = monochrome_logs ? '' : "\033[4;30m"
    colorcodes['ured']    = monochrome_logs ? '' : "\033[4;31m"
    colorcodes['ugreen']  = monochrome_logs ? '' : "\033[4;32m"
    colorcodes['uyellow'] = monochrome_logs ? '' : "\033[4;33m"
    colorcodes['ublue']   = monochrome_logs ? '' : "\033[4;34m"
    colorcodes['upurple'] = monochrome_logs ? '' : "\033[4;35m"
    colorcodes['ucyan']   = monochrome_logs ? '' : "\033[4;36m"
    colorcodes['uwhite']  = monochrome_logs ? '' : "\033[4;37m"

    // High Intensity
    colorcodes['iblack']  = monochrome_logs ? '' : "\033[0;90m"
    colorcodes['ired']    = monochrome_logs ? '' : "\033[0;91m"
    colorcodes['igreen']  = monochrome_logs ? '' : "\033[0;92m"
    colorcodes['iyellow'] = monochrome_logs ? '' : "\033[0;93m"
    colorcodes['iblue']   = monochrome_logs ? '' : "\033[0;94m"
    colorcodes['ipurple'] = monochrome_logs ? '' : "\033[0;95m"
    colorcodes['icyan']   = monochrome_logs ? '' : "\033[0;96m"
    colorcodes['iwhite']  = monochrome_logs ? '' : "\033[0;97m"

    // Bold High Intensity
    colorcodes['biblack']  = monochrome_logs ? '' : "\033[1;90m"
    colorcodes['bired']    = monochrome_logs ? '' : "\033[1;91m"
    colorcodes['bigreen']  = monochrome_logs ? '' : "\033[1;92m"
    colorcodes['biyellow'] = monochrome_logs ? '' : "\033[1;93m"
    colorcodes['biblue']   = monochrome_logs ? '' : "\033[1;94m"
    colorcodes['bipurple'] = monochrome_logs ? '' : "\033[1;95m"
    colorcodes['bicyan']   = monochrome_logs ? '' : "\033[1;96m"
    colorcodes['biwhite']  = monochrome_logs ? '' : "\033[1;97m"

    return colorcodes
}