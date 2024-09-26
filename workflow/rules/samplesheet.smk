rule:
    output:
        'results/raw_seq_info.csv'
    params:
        path=config['samplesheet']['seq_info']
    resources:
        slurm_partition='datatransfer'
    localrule: True
    envmodules:
        'rclone/1.67.0'
    shell:
        'rclone copyto "nextcloud:{params.path}" {output}'


rule:
    output:
        'results/raw_sample_info.xlsx'
    params:
        path=config['samplesheet']['sample_info']
    resources:
        slurm_partition='datatransfer'
    localrule: True
    envmodules:
        'rclone/1.67.0'
    shell:
        'rclone copyto "nextcloud:{params.path}" {output}'


checkpoint samplesheet:
    input:
        'results/raw_sample_info.xlsx'
    params:
        data_glob=f"'{config['data']['directory']}*.fastq.gz'"
    output:
        multiext('results/samplesheet', '.duckdb', '.csv')
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        export MEMORY_LIMIT="8GB" \
               SLURM_CPUS_PER_TASK=2 \
               FASTQS_DIR={params.data_glob} \
               SAMPLESHEET="{input}"

        duckdb {output[0]} \
            -c ".read workflow/scripts/create_fastqs_db.sql"

        duckdb -init workflow/scripts/create_types.sql {output[0]} \
            -c ".read workflow/scripts/create_sample_info_db.sql"

        duckdb -csv -init workflow/scripts/create_samplesheet_db.sql {output[0]} \
            -c "set enable_progress_bar = false; copy samplesheet to '/dev/stdout';" > {output[1]}
        '''


rule:
    input:
        expand(
            'results/{info}.csv',
            info=['raw_seq_info', 'samplesheet']
        )
    output:
        touch('results/samplesheet.done')
    localrule: True