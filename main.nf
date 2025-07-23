#!/usr/env/bin nextflow

/*
 *  PIPELINE: main.nf
 *
 *  Description:
 *      SAMap-based cross-species transcriptome mapping pipeline.
 *      Performs preprocessing of input metadata, reciprocal BLAST between
 *      species, SAMap alignment, and visualization of results.
 *
 *  Inputs:
 *      - data/transcriptomes/*.fasta      Input transcriptome FASTA files
 *      - data/*.h5ad || *.rds             Precomputed AnnData files or raw rds files
 *      - sample_sheet.csv                 Sample metadata sheet
 *
 *  Workflow Overview:
 *      0. Verify sample sheet format and required columns
 *      1. Ensure all samples have h5ad files
 *      2. Classify FASTA files as nucleotide or protein
 *      3. Run pairwise BLAST comparisons if no precomputed maps are provided
 *      4. Merge BLAST maps into a single directory
 *      5. Load SAM objects from the AnnData h5ad files
 *      6. Build the SAMap object from the SAM objects and the BLAST maps
 *      7. Run SAMap on the SAMAP object to generate mapping results
 *      8. Visualize the SAMap results
 *
 *  Parameters:
 *      --run_id        Run ID provided by user. If none is provided a timestamp is used. Default: null
 *      --sample_sheet  Path to the sample sheet provided by user. Default: 'sample_sheet.csv'
 *      --data_dir      Path to the directory containing the data. Default: 'data'
 *      --maps_dir      Path to a directory containing precomputed BLAST maps if any are provided. 
 *                      Any value other than null will skip the BLAST module. Default: null
 *      --verbose       Print verbose channel information
 *      --outdir        The directory all where all results will be stored. Default: 'out'
 *
 * Outputs:
 *      outdir/
 *         00_verify/*
 *         01_ensure_h5ad/*
 *         02_classify/*
 *         03_run_blast_pair/*  - if no maps_dir is provided
 *         04_merge_maps/*      - if no maps_dir is provided
 *         05_load_sam/*
 *         06_build_samap/*
 *         07_run_samap/*
 *         08_visualize/*
 *
 *  Author:     Ryan Sonderman
 *  Created:    2025-06-12
 */

// Import the required modules 
include { VERIFY_SAMPLESHEET } from './modules/00_verify_samplesheet.nf'
include { ENSURE_H5AD        } from './modules/01_ensure_h5ad.nf'
include { CLASSIFY_FASTA     } from './modules/02_classify_fasta.nf'
include { RUN_BLAST_PAIR     } from './modules/03_run_blast_pair.nf'
include { MERGE_MAPS         } from './modules/04_merge_maps.nf'
include { LOAD_SAM           } from './modules/05_load_sam.nf'
include { BUILD_SAMAP        } from './modules/06_build_samap.nf'
include { RUN_SAMAP          } from './modules/07_run_samap.nf'
include { VISUALIZE_SAMAP    } from './modules/08_visualize_samap.nf'

workflow {
    // ╔═ PREPROCESSING STEPS ════════════════════════════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝

    run_id = params.run_id ?: "${new Date().format('yyyyMMdd_HHmmss')}"
    run_id_ch = Channel.value(run_id)
    // params.outdir = "${params.outdir}/${run_id}" // Not working gotta fix it later
    
    data_dir        = Channel.fromPath(params.data_dir)
    sample_sheet    = Channel.fromPath(params.sample_sheet)


    // ╔═ VERIFY THE SAMPLESHEET ═════════════════════════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    VERIFY_SAMPLESHEET(
        run_id_ch,
        sample_sheet,
    )
    sample_sheet = VERIFY_SAMPLESHEET.out.sample_sheet
    // Read the sample sheet and store the metadata in a channel of dicts
    meta_ch = sample_sheet
        .splitCsv(header: true)
        .map { row ->
            def sample_meta = [
                id:         row.id,
                id2:        row.id2,
                annotation: row.annotation,
            ]
            def matrix = file(row.matrix)
            def fasta  = file(row.fasta)
            tuple( sample_meta, matrix, fasta )
        }
    params.verbose && meta_ch.view { it -> "Sample: ${it}\n" }


    // ╔═ MAKE SURE MATRIX FILES ARE H5AD ════════════════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    ENSURE_H5AD(
        run_id_ch,
        meta_ch,
    )
    converted_meta_ch = ENSURE_H5AD.out.converted_meta
    h5ad_files        = ENSURE_H5AD.out.h5ad_file
    params.verbose && converted_meta_ch.view { it -> "Converted meta channel: ${it}\n" }
    params.verbose && h5ad_files.view        { it -> "H5AD files channel: ${it}\n"     }


    // ╔═ CLASSIFY THE FASTA AS PROTEIN OR NUCLEOTIDE ════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    CLASSIFY_FASTA(
        run_id_ch,
        converted_meta_ch,
    )
    classified_meta_ch_raw = CLASSIFY_FASTA.out.classified_sample_raw
    params.verbose && classified_meta_ch_raw.view { it -> "Raw classified meta channel: ${it}\n" }
    // Put the classification into the sample_meta
    classified_meta_ch = classified_meta_ch_raw
        .map { row ->
            def sample_meta    = row[0]
            def matrix_file    = row[1]
            def fasta_file     = row[2]
            def classification = row[3].trim()
            def updated_meta = sample_meta + [ type: classification ]
            tuple( updated_meta, matrix_file, fasta_file )
        }
    params.verbose && classified_meta_ch.view { it -> "Classified meta channel: ${it}\n" }


    // ╔═ RUN PAIRWISE BLAST COMPARISONS ═════════════════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    if (params.maps_dir) {
        maps_dir = Channel.fromPath(params.maps_dir)
    } else {
        pairs_channel = classified_meta_ch
            .combine(classified_meta_ch)
            .filter { metaA, _matA, _fasA, metaB, _matB, _fasB -> 
            metaA.id < metaB.id }
        params.verbose && pairs_channel.view { it -> "Pairs channel: ${it}\n" }

        RUN_BLAST_PAIR(
            run_id_ch,
            pairs_channel,
        )

        maps_ch = RUN_BLAST_PAIR.out.maps
            .collect()
            .flatten()
            .map { it.getParent() }
            .distinct()
            .collect()
            .map { it -> tuple(it) }
        params.verbose && maps_ch.view { it -> "Maps channel: ${it}\n" }

        MERGE_MAPS(
            run_id,
            maps_ch
        )

        maps_dir = MERGE_MAPS.out.maps
        params.verbose && maps_dir.view { it -> "Maps directory: ${it}\n"}
    }


    // ╔═ LOAD THE H5AD FILES INTO SAM OBJECTS ═══════════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    LOAD_SAM(
        run_id_ch,
        classified_meta_ch,
    )
    sams = LOAD_SAM.out.sam
    params.verbose && sams.view { it -> "Loaded SAM object: ${it}\n" }


    // ╔═ USE THE SAM OBJECTS AND BLAST MAPPINGS TO BUILD A SAMAP OBJECT ═════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    sams_list = sams
        .collect()
    params.verbose && sams_list.view { it -> "SAM objects list: ${it}\n" }
    BUILD_SAMAP(
        run_id_ch,
        sams_list,
        maps_dir,
        data_dir,
    )
    samap = BUILD_SAMAP.out.samap
    params.verbose && samap.view { it -> "SAMAP ojbect: ${it}\n" }


    // ╔═ RUN THE SAMAP ALGORITHM ON THE NEW OBJECT ══════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    RUN_SAMAP(
        run_id_ch,
        samap,
    )
    samap_results = RUN_SAMAP.out.results
    params.verbose && samap_results.view { it -> "SAMAP results: ${it}\n" }


    // ╔═ VISUALIZE THE RESULTS OF SAMAP ═════════════════════════════════════════════╗
    // ║                                                                              ║
    // ╚══════════════════════════════════════════════════════════════════════════════╝


    VISUALIZE_SAMAP(
        run_id_ch,
        samap_results,
        classified_meta_ch.collect(),
    )
}
