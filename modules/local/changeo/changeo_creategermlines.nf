process CHANGEO_CREATEGERMLINES {
    tag "$meta.id"
    label 'process_low'
    label 'immcantation'


    conda "bioconda::changeo=1.3.0 bioconda::igblast=1.22.0 conda-forge::wget=1.20.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-7d8e418eb73acc6a80daea8e111c94cf19a4ecfd:a9ee25632c9b10bbb012da76e6eb539acca8f9cd-1' :
        'biocontainers/mulled-v2-7d8e418eb73acc6a80daea8e111c94cf19a4ecfd:a9ee25632c9b10bbb012da76e6eb539acca8f9cd-1' }"

    input:
    tuple val(meta), path(tab) // sequence tsv table in AIRR format
    path(imgt_base) // imgt db

    output:
    tuple val(meta), path("*germ-pass.tsv"), emit: tab
    path("*_command_log.txt"), emit: logs
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    CreateGermlines.py -d ${tab} \\
    -r ${imgt_base}/${meta.species}/vdj/ \\
    -g dmask --format airr \\
    --log ${meta.id}.log --outname ${meta.id} $args > ${meta.id}_create-germlines_command_log.txt
    ParseLog.py -l ${meta.id}.log -f ID V_CALL D_CALL J_CALL

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        igblastn: \$( igblastn -version | grep -o "igblast[0-9\\. ]\\+" | grep -o "[0-9\\. ]\\+" )
        changeo: \$( CreateGermlines.py --version | awk -F' '  '{print \$2}' )
    END_VERSIONS
    """
}
