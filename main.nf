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
 *      --outdir   The directory all where all results will be stored. Default: 'out'
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
include { VERIFY_SAMPLESHEET }  from './modules/00_verify_samplesheet.nf'
include { ENSURE_H5AD }         from './modules/01_ensure_h5ad.nf'
include { CLASSIFY_FASTA }      from './modules/02_classify_fasta.nf'
include { RUN_BLAST_PAIR }      from './modules/03_run_blast_pair.nf'
include { MERGE_MAPS }          from './modules/04_merge_maps.nf'
include { LOAD_SAM }            from './modules/05_load_sam.nf'
include { BUILD_SAMAP }         from './modules/06_build_samap.nf'
include { RUN_SAMAP }           from './modules/07_run_samap.nf'
include { VISUALIZE_SAMAP }     from './modules/08_visualize_samap.nf'

workflow {
    // Generate run ID unless one is provided
    run_id = params.run_id ?: "${new Date().format('yyyyMMdd_HHmmss')}"
    run_id_ch = Channel.value(run_id)
    // params.outdir = "${params.outdir}/${run_id}" // Not working gotta fix it later
    

    // Stage static input files
    data_dir        = Channel.fromPath(params.data_dir)
    sample_sheet    = Channel.fromPath(params.sample_sheet)


    // Verify the sample sheet format and required columns
    VERIFY_SAMPLESHEET(
        run_id_ch,
        sample_sheet,
    )
    sample_sheet = VERIFY_SAMPLESHEET.out.sample_sheet


    // Read the sample sheet and store the metadata in a channel of dicts
    meta_ch = sample_sheet
        .splitCsv(header: true)
        .map { row ->
            row + [
                id: row.id,
                matrix: file(row.matrix),
                fasta: file(row.fasta),
                annotation: row.annotation,
            ]
        }
    // samples_ch.view { it -> "Sample sheet: ${it}" }


    // Ensure all samples have h5ad files
    ENSURE_H5AD(
        run_id_ch,
        meta_ch,
        data_dir.first()
    )
    converted_h5ad_ch = ENSURE_H5AD.out.converted_matrix
    h5ad_files = ENSURE_H5AD.out.h5ad_file
    // Add converted matrices to the metadata
    converted_meta_ch = converted_h5ad_ch
        .map { meta, h5ad_file ->
            meta + [ matrix: h5ad_file.trim() ]
        }


    // Classify FASTA files as either nucleotide or protein
    CLASSIFY_FASTA(
        run_id_ch,
        converted_meta_ch,
        data_dir.first()
    )
    classified_fasta_ch = CLASSIFY_FASTA.out.classified_sample


    // Inject the new classifications as 'type'
    classified_meta_ch = classified_fasta_ch
        .map { meta, classification ->
            meta + [ type: classification.trim() ]
        }
    // classified_meta_ch.view()


    // Run pairwise blast comparisons if no maps were passed as param
    if (params.maps_dir) {
        maps_dir = Channel.fromPath(params.maps_dir)
    } else {
        // Generate unique ordered pairs
        pairs_channel = classified_meta_ch
            .combine(classified_meta_ch)
            .filter { a, b -> a.id < b.id }
        // pairs_channel.view { it -> "Pairs channel: ${it}" }
        // Compute BLAST maps from pairs channel
        RUN_BLAST_PAIR(
            run_id_ch,
            pairs_channel,
            data_dir.first(),
        )
        maps_ch = RUN_BLAST_PAIR.out.maps
            .collect()
            .flatten()
            .map { it.getParent() }
            .distinct()
            .collect()
            .map { it -> tuple(it) }
        // Merge the maps into a single directory
        MERGE_MAPS(
            run_id,
            maps_ch
        )
        maps_dir = MERGE_MAPS.out.maps
    }


    // Load SAM objects from the AnnData h5ad files
    LOAD_SAM(
        run_id_ch,
        classified_meta_ch,
        data_dir.first(),
        h5ad_files,
    )
    sams = LOAD_SAM.out.sam
    // sams.view { it -> "Loaded SAM objects: ${it}" }



    // Build the SAMap object from the SAM objects and the BLAST maps
    sams_list = sams
        .collect()
    // sams_list.view { it -> "SAM objects list: ${it}" }
    BUILD_SAMAP(
        run_id_ch,
        sams_list,
        maps_dir,
        data_dir,
    )
    samap = BUILD_SAMAP.out.samap


    // Run SAMap on the SAMAP object to generate mapping results
    RUN_SAMAP(
        run_id_ch,
        samap,
    )
    samap_results = RUN_SAMAP.out.results


    // Visualize the SAMap results
    VISUALIZE_SAMAP(
        run_id_ch,
        samap_results,
        classified_meta_ch.collect(),
    )
}
