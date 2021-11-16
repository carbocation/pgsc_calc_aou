// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process COMBINE_BIM {
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::mawk=1.3.4" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mawk:1.3.4--h779adbc_4"
    } else {
        container "quay.io/biocontainers/mawk:1.3.4--h779adbc_4"
    }

    input:
    tuple val(meta), path(bims)

    output:
    tuple val(meta), path("*.combined"), emit: variants
    path "versions.yml"            , emit: versions

    script:
    """
    mawk \\
        'FNR == 1 && NR != 1 { while (/^#CHROM/) next }
        { print }' ${bims} > ${meta.id}.combined

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        mawk: \$(echo \$(mawk -W version 2>&1) | cut -f 2 -d ' ')
    END_VERSIONS
    """
}