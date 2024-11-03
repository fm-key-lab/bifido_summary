rule:
    output:
        'data_lake/indexes/enums.duckdb'
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        duckdb -init config/.duckdbrc {output} \
          -c ".read workflow/scripts/create_enums.sql"
        '''


for info, exe in zip(['seq_info', 'sample_info'], ['csv', 'xlsx']):
    rule:
        name:
            f'get_{info}'
        output:
            f'results/raw_{info}.{exe}'
        params:
            path=config['samplesheet'][info]
        resources:
            slurm_partition='datatransfer'
        localrule: True
        envmodules:
            'rclone/1.67.0'
        shell:
            'rclone copyto "nextcloud:{params.path}" {output}'


rule:
    output:
        'data_lake/indexes/fastqs-indexswapped.csv'
    params:
        glob=f"'{config['data']['directory']}*.fastq.gz'",
        pat=config['data']['pat'],
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        export GLOB={params.glob} PAT={params.pat}

        duckdb -init config/.duckdbrc \
          -c ".read workflow/scripts/collect_fastqs.sql" > {output}
        '''


rule:
    input:
        enums='data_lake/indexes/enums.duckdb',
        info='results/raw_sample_info.xlsx',
    output:
        'data_lake/indexes/samples.duckdb'
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        duckdb -init config/.duckdbrc \
          -c "attach '{input.enums}' as enums_db (read_only);
          attach '{output}' as info_db;
          copy from database enums_db to info_db;"

        export SAMPLE_INFO="{input.info}"

        duckdb -init config/.duckdbrc {output} \
          -c ".read workflow/scripts/clean_sample_info.sql"
        '''


rule:
    input:
        info='results/raw_seq_info.csv',
    output:
        'data_lake/indexes/seq.duckdb'
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        export SEQ_INFO="{input.info}"

        duckdb -init config/.duckdbrc {output} \
          -c ".read workflow/scripts/clean_seq_info.sql"
        '''


rule:
    input:
        fastqs='data_lake/indexes/fastqs-indexswapped.csv',
        seqinfo='data_lake/indexes/seq.duckdb',
    output:
        'data_lake/indexes/fastqs.csv'
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        export FASTQS="{input.fastqs}"

        duckdb -readonly -init config/.duckdbrc {input.seqinfo} \
          -c ".read workflow/scripts/fix_index_swap.sql" > {output}
        '''


checkpoint fastqs:
    input:
        fastqs='data_lake/indexes/fastqs.csv',
        samples='data_lake/indexes/samples.duckdb'
    output:
        'results/samplesheets/kraken_bracken.csv'
    localrule: True
    envmodules:
        'duckdb/1.0'
    shell:
        '''
        export FASTQS="{input.fastqs}"

        duckdb -readonly -init config/.duckdbrc {input.samples} \
          -c ".read workflow/scripts/create_kraken_bracken_samplesheet.sql" > {output}
        '''