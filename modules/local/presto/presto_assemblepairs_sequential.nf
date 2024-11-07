process PRESTO_ASSEMBLEPAIRS_SEQUENTIAL {
    tag "$meta.id"
    label 'process_long_parallelized'
    label 'immcantation'

    conda "bioconda::presto=0.7.1 bioconda::igblast=1.22.0 conda-forge::wget=1.20.1 conda-forge::biopython=1.79"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-865ad74e0cfd6de39e9e3ade759d826fce726425:eb705f041731c0cf4f5e7595889cf9d14a05031b-0' :
        'biocontainers/mulled-v2-865ad74e0cfd6de39e9e3ade759d826fce726425:eb705f041731c0cf4f5e7595889cf9d14a05031b-0' }"

    input:
    tuple val(meta), path(R1), path(R2) // reads in fastq format
    path(igblast) // igblast references

    output:
    tuple val(meta), path("*_assemble-pass.fastq"), emit: reads
    path("*_command_log.txt"), emit: logs
    path("*_table.tab")
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    AssemblePairs.py sequential -1 $R2 -2 $R1 --nproc ${task.cpus} \\
        -r "${igblast}/fasta/imgt_${meta.species}_${meta.locus.toLowerCase()}_v.fasta" \\
        $args \\
        --outname ${meta.id} --log ${meta.id}.log > ${meta.id}_command_log.txt
    ParseLog.py -l ${meta.id}.log $args2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        presto: \$( AssemblePairs.py --version | awk -F' '  '{print \$2}' )
    END_VERSIONS
    """
}
