process PRESTO_MASKPRIMERS_EXTRACT {
    tag "$meta.id"
    label "process_high"
    label 'immcantation'

    conda "bioconda::presto=0.7.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/presto:0.7.1--pyhdfd78af_0' :
        'biocontainers/presto:0.7.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(read)
    val(extract_start)
    val(extract_length)
    val(extract_mode)
    val(barcode)
    val(suffix)

    output:
    tuple val(meta), path("*_primers-pass.fastq") , emit: reads
    path "*.txt", emit: logs
    path "*.tab", emit: log_tab
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args?: ''
    def args2 = task.ext.args2?: ''
    def barcode = barcode ? '--barcode' : ''
    """
    MaskPrimers.py extract \\
    --nproc ${task.cpus} \\
    -s $read \\
    --start ${extract_start} \\
    --len ${extract_length} \\
    $barcode \\
    $args \\
    --mode ${extract_mode} \\
    --outname ${meta.id}_${suffix} \\
    --log ${meta.id}_${suffix}.log >> ${meta.id}_command_log_${suffix}.txt
    ParseLog.py -l *.log $args2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        presto: \$( MaskPrimers.py --version | awk -F' '  '{print \$2}' )
    END_VERSIONS
    """
}
