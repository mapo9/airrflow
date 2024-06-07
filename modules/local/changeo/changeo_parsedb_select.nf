process CHANGEO_PARSEDB_SELECT {
    tag "$meta.id"
    label 'process_low'
    label 'immcantation'


    conda "bioconda::changeo=1.3.0 bioconda::igblast=1.22.0 conda-forge::wget=1.20.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-7d8e418eb73acc6a80daea8e111c94cf19a4ecfd:a9ee25632c9b10bbb012da76e6eb539acca8f9cd-1' :
        'biocontainers/mulled-v2-7d8e418eb73acc6a80daea8e111c94cf19a4ecfd:a9ee25632c9b10bbb012da76e6eb539acca8f9cd-1' }"

    input:
    tuple val(meta), path(tab) // sequence tsv in AIRR format

    output:
    tuple val(meta), path("*parse-select.tsv"), emit: tab // sequence tsv in AIRR format
    path("*_command_log.txt"), emit: logs //process logs
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    if (meta.locus.toUpperCase() == 'IG'){
        """
        ParseDb.py select -d $tab $args --outname ${meta.id} > ${meta.id}_select_command_log.txt

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            igblastn: \$( igblastn -version | grep -o "igblast[0-9\\. ]\\+" | grep -o "[0-9\\. ]\\+" )
            changeo: \$( ParseDb.py --version | awk -F' '  '{print \$2}' )
        END_VERSIONS
        """
    } else if (meta.locus.toUpperCase() == 'TR'){
        """
        ParseDb.py select -d $tab $args2 --outname ${meta.id} > "${meta.id}_command_log.txt"

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            igblastn: \$( igblastn -version | grep -o "igblast[0-9\\. ]\\+" | grep -o "[0-9\\. ]\\+" )
            changeo: \$( ParseDb.py --version | awk -F' '  '{print \$2}' )
        END_VERSIONS
        """
    }
}
