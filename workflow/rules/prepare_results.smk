rule record_total_reads:
    input:
        ancient(expand(
            'results/{species}/multiqc/multiqc_data/multiqc_fastp.yaml',
            species=config['wildcards']['species'].split('|')
        ))
    output:
        'results/total_reads.duckdb',
    resources:
        cpus_per_task=8,
        mem_mb=16_000
    envmodules:
        'yq/4.44.3',
        'duckdb/nightly'
    shell:
        '''
        export MEMORY_LIMIT="$(({resources.mem_mb} / 1100))GB"

        yq -o=csv '.[] | [key, .summary.before_filtering.total_reads, .summary.after_filtering.total_reads]' {input} |\
          duckdb {output} -c ".read workflow/scripts/parse_fastp_multiqc_output.sql"
        '''