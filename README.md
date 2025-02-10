# nf-miRNA

```

        ▄▄▄▄  ▗▞▀▀▘  ▄▄▄▄  ▄ ▗▄▄▖ ▗▖  ▗▖ ▗▄▖ 
        █   █ ▐▌     █ █ █ ▄ ▐▌ ▐▌▐▛▚▖▐▌▐▌ ▐▌
        █   █ ▐▛▀▘   █   █ █ ▐▛▀▚▖▐▌ ▝▜▌▐▛▀▜▌
              ▐▌             ▐▌ ▐▌▐▌  ▐▌▐▌ ▐▌

```
## 1. Introduction

**nf-mirna** is a complete pipeline to process, align and analyse deep sequencing miRNA reads. This pipeline is based on the nf-core pipeline [smrnaseq](https://nf-co.re/smrnaseq/2.4.0/) v2.4.0, and it is built using [Nextflow](https://www.nextflow.io/), a workflow tool to run tasks across multiple compute infrastructures. It can use Docker/Singularity making installation and results highly reproducible.

![Pipeline flow chart](./flowchart.png)

## 2. Pipeline Summary

1. Quality check and trimming
    - Raw read QC (`fastqc`)
    - Adapter trimming, miRNA QC, and FASTQ to FASTA conversion (`miRTrace`)
2. miRNA quantification
    - Alignment against miRNA mature reference (`bowtie`)
    - Quantification of miRNA counts from mature alignment (`samtools idxstats`)
    - Alignment of unmapped reads to genome reference (`bowtie`) (Optional)
    - Quantification of miRNA counts from genome alignment (`htseq-count`) (Optional)
3. Novel miRNAs discovery
    - Mapping against reference genome and novel miRNA discovery with the miRDeep2 module (`miRDeep2`) (Optional)
4. Summary results and QCs (`multiqc`)
5. Summary of pipeline execution (`nextflow`)

## 3. Usage

You can test the pipeline as follows:

```bash
nextflow run nf-mirna \
    -profile <test,test_genome>,singularity \
    --outdir <OUTDIR>
```

In order to use the pipeline with your own data, first prepare a `samplesheet.csv` with yout input data that looks as follows:

```
sample,fastq_1
sample_1,10004_S37_R1_001.fastq.gz
sample_2,1006_S18_R1_001.fastq.gz
sample_3,4025_S11_R1_001.fastq.gz
sample_4,2001_S25_R1_001.fastq.gz
```

Each row represents a fastq file (single-end). Now, you can run the pipeline using:

```bash
nextflow run nf-mirna \
    -profile <singularity,docker>,<protocol> ... \
    --input samplesheet.csv \
    --genome 'path/to/genome[.fa|.ga.gz]' \
    --genome_index 'path/to/genome_index[dir|.tar.gz]' \
    --mirna_gtf 'path/to/mirna.gtf' \
    --outdir <OUTDIR>
```

If you need an extended summary of all possible parameters of the pipeline, you can do so by running `nextflow run nf-mirna --help`.

## 4. Results Overview

A normal run of the pipeline will generate a results directory structure similar to the following:

```bash
results/
├── fastqc          # raw reads QC
├── mirtrace        # miRNA QC
├── bowtie
│   ├── mature      # results of bowtie alignment against mature ref
│   └── genome      # results of bowtie alignemnt against genome
├── mirna_quant     # miRNA raw counts of mature alignment
├── genome_quant    # miRNA raw counts of genome alignment
├── mirdeep2        # novel miRNA discovery results
├── multiqc         # summary reports of pipeline steps
└── pipeline_info   # nextflow pipeline execution reports
```

### 4.1. FastQC

The directory `fastqc` will contain an output directory for every sample inputed in the pipeline (after the `sample` column in `samplesheet.csv`):

**Output directory**: `results/fastqc/{sample.id}/`

- `{sample.id}.fastqc.html`: FastQC report containing quality metrics.
- `{sample.id}.fastqc.zip`: Zip archive containing the FastQC reports, tab-delimited data and plot images.

### 4.2. miRTrace

The directory `mirtrace` will contain an output directory for every sample inputed in the pipeline (after the `sample` column in `samplesheet.csv`).

**Output directory**: `results/mirtrace/{sample.id}/`

- `mirtrace.log`: The log of the miRTrace command run.
- `mirtrace-report.html`: An interactive HTML report summarizing all output statistics from miRTrace.
- `mirtrace-results.json`: A JSON file with all output statistics from miRTrace.
- `mirtrace-stats*.tsv`: Tab-separated statistic files.
- `qc_passed_reads.all.uncollapse/{sample.id}.mirtrace.fa.gz`: Compressed FASTA file per sample with sequence reads that passed QC in miRTrace.

### 4.3. Bowtie1

The directory `bowtie` will only be generated if the `--save_intermediates` parameter is set to `true`. It will contain one subdirectory for the mature reference alignment and one for the genome alignment (if not skipped).

**Output directory**: `results/bowtie/{mature|genome}/{sample.id}/`

- `{sample.id}.out`: The log of the Bowtie1 alignment.s
- `{sample.id}.bam`: Aligned BAM file results.
- `{sample.id}.stats`: The `stats` output of the alignment.
- `{sample.id}.flagstats`: The `flagstats` output of the alignment.
- `{sample.id}_unaligned.fa.gz`: The unaligned reads in a compressed FASTA format resulting from the mature reference alignment. This file is not generated during the genome alignment.

### 4.4. Mature miRNA Quantification (samtools idxstats)

The directory `mirna_quant` will contain the quantification of the resulting BAM alignemnt files agaisnt the mature reference.

**Output directory**: `results/mirna_quant/`

- `{sample.id}.mature.idxstats.tsv`: Tab-separated file containing the miRNA counts from the mature reference alignment.

### 4.5. Genome miRNA Quantification (htseq-count)

The directory `genome_quant` will contain the quantification of the resulting BAM alignment files agaisnt the genome reference. This output directory will not be generated if the genome alignment is skipped.

**Output directory**: `results/genome_quant/`

- `{sample.id}.genome.htseq.tsv`: Tab-separated file containing the miRNA counts from the genome reference alignment.

### 4.6. miRDeep2

The directory `mirdeep2` will contain the results of the novel miRNA discovery run with an output directory for every sample inputed in the pipeline (after the `sample` column in `samplesheet.csv`). This output directory will not be generated if the miRDeep2 module is skipped.

**Output directory**: `results/mirdeep2/{sample.id}/`

- `{sample.id}_mirdeep2.log`: The log of the miRDeep2 run.
- `{sample.id}_mirdeep2.bed`: File with the known miRNAs in BED format.
- `{sample.id}_mirdeep2.csv`: File with an overview of all detected miRNAs (known and novel) in CSV format.
- `{sample.id}_mirdeep2.html`: A HTML report with an overview of all detected miRNAs (known and novel) in HTML format.
- `miRNAs_expressed_all_samples.csv`: File with the known miRNAs in CSV format.
- `{sample.id}.genome.mirdeep.arf`: Intermediate file containing the alignment results of the miRDeep2 mapper module. Will only be generated if the `--save_intermediates` parameters is set to `true`.
- `{sample.id}.genome.mirdeep.fa`: Intermediate file containing the mapped reads from the miRDeep2 mapper module. Will only be generated if the `--save_intermediates` parameters is set to `true`.

### 4.7. MultiQC

The directory `multiqc` will containg the pipeline QC from the supported tools (e.g., FastQC, bowtie1), which include most of this pipeline steps.

**Output directory**: `results/multiqc/`

- `multiqc_report.html`: an interactive HTML report of all compatible pipeline steps.
- `multiqc_data/`: directory containing summarised data from all compatible pipeline steps generated by MultiQC.

### 4.8. Pipeline Information

The directory `pipeline_info` will contain various reports relevant to running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.