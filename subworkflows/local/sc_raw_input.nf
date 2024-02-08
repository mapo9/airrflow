include { CELLRANGER_VDJ                                                } from '../../modules/nf-core/cellranger/vdj/main'
include { RENAME_FILE as RENAME_FILE_TSV                                } from '../../modules/local/rename_file'
include { CHANGEO_CONVERTDB_FASTA as CHANGEO_CONVERTDB_FASTA_FROM_AIRR  } from '../../modules/local/changeo/changeo_convertdb_fasta'

include { MIXCR_FLOW                    } from './mixcr_flow'


workflow SC_RAW_INPUT {

    take:
    ch_reads_single // meta, reads
    

    main:

    ch_versions = Channel.empty()
    ch_logs = Channel.empty()

    // validate library generation method parameter
    if (params.library_generation_method == 'specific_pcr_5p_race_umi') {
        if (params.vprimers) {
            error "The transcript-specific primer, 5'-RACE, UMI library generation method does not require V-region primers, please provide a reference file instead or select another library method option."
        } else if (params.race_linker) {
            error "The transcript-specific primer, 5'-RACE, UMI library generation method does not require the --race_linker parameter, please provide a reference file instead or select another library method option."
        } 
        if (params.cprimers)  {
            error "The transcript-specific primer, 5'-RACE, UMI library generation method does not require C-region primers, please provide a reference file instead or select another library method option."
        }
        if (params.umi_length > 0)  {
            error "The transcript-specific primer, 5'-RACE, UMI library generation method does not require to set the UMI length, please provide a reference file instead or select another library method option."
        } 
        if (params.reference_10x)  {
            ch_sc_refence = Channel.fromPath(params.reference_10x, checkIfExists: true)
        } else {
            error "The transcript-specific primer, 5'-RACE, UMI library generation method requires you to provide a reference file."
        }
    } else {
        error "The provided library generation method is not supported. Please check the docs for `--library_generation_method`."
    }


    CELLRANGER_VDJ (
        ch_reads_single,
        ch_sc_refence
    )
    ch_versions = ch_versions.mix(CELLRANGER_VDJ.out.versions)

    ch_cellranger_out = CELLRANGER_VDJ.out.outs

    ch_cellranger_out
        .map { meta, out_files -> 
                [ meta, out_files.find { it.endsWith("airr_rearrangement.tsv") }] 
            }
        .set { ch_cellranger_airr }

    // TODO : add VALIDATE_INPUT Module
    // this module requires input in csv format... Might need to create this in an extra module

    // rename tsv file to unique name
    RENAME_FILE_TSV( 
                ch_cellranger_airr 
            )
        .set { ch_renamed_tsv }

    if (params.kit) {
        MIXCR_FLOW(
            ch_reads_single
        )
        ch_versions = ch_versions.mix(MIXCR_FLOW.out.versions)
    }

    
    // convert airr tsv to fasta
    CHANGEO_CONVERTDB_FASTA_FROM_AIRR(
                RENAME_FILE_TSV.out.file
            )
    
    ch_fasta = CHANGEO_CONVERTDB_FASTA_FROM_AIRR.out.fasta

    RENAME_FILE.out.file.dump(tag:"file")

    emit:
    versions = ch_versions
    // complete cellranger output
    outs = ch_cellranger_out
    // cellranger output in airr format
    airr = ch_cellranger_airr
    // cellranger output converted to FASTA format
    fasta = ch_fasta

}
