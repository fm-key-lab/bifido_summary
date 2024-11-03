def paired_fastqs(wildcards):
    import pandas as pd

    return (
        pd.read_csv(
            checkpoints.fastqs.get(**wildcards).output[0]
        )
        # NOTE: Not all FASTQs can be resolved to IDs
        .dropna()
        .query(
            f"sample == {wildcards['sample']}"
        )
        .filter(like='fastq', axis=1)
        .values
        .flatten()
    )


rule kraken2:
    input:
        paired_fastqs
    output:
        'results/kraken2/{sample}.kraken2',
        'results/kraken2/{sample}.k2report',
    params:
        db=config['public_data']['kraken_db'],
    resources:
        cpus_per_task=4,
        mem_mb=96_000,
        runtime=10,
    envmodules:
        'intel/21.2.0',
        'impi/2021.2',
        'kraken2/2.1.3'
    shell:
        '''
        export OMP_PLACES=threads
        
        kraken2 \
          --db {params.db} \
          --threads {resources.cpus_per_task} \
          --report-minimizer-data \
          --paired \
          --minimum-hit-groups 3 \
          --output {output[0]} \
          --report {output[1]} \
          {input}
        '''


rule bracken:
    input:
        'results/kraken2/{sample}.k2report',
    output:
        'results/bracken/{sample}.bracken',
        'results/bracken/{sample}.breport',
    params:
        db=config['public_data']['kraken_db'],
    resources:
        runtime=5,
    envmodules:
        'bracken/2.9'
    shell:
        'bracken -d {params.db} -r 100 -i {input} -o {output[0]} -w {output[1]}'


def abundance_output(wildcards):
    import pandas as pd

    sample_ids = (
        pd.read_csv(
            checkpoints.fastqs.get(**wildcards).output[0]
        )
        # NOTE: Not all FASTQs can be resolved to IDs
        .dropna()
        ['sample'].astype(str)
    )

    return expand(
        [
            'results/bracken/{sample}.bracken',
            'results/bracken/{sample}.breport',
        ],
        sample=sample_ids
    )


rule:
    input:
        abundance_output
    output:
        'data_lake/indexes/abundance.duckdb',
    params:
        glob="'results/bracken/*.bracken'"
    resources:
        cpus_per_task=8,
        mem_mb=4_000,
        runtime=15
    envmodules:
        'duckdb/nightly'
    shell:
        '''
        export MEMORY_LIMIT="$(({resources.mem_mb} / 1200))GB"
        export GLOB={params.glob}
        
        duckdb -init config/.duckdbrc {output} \
          -c ".read workflow/scripts/clean_bracken_output.sql"
        '''


checkpoint reference_genomes:
    input:
        samples='data_lake/indexes/samples.duckdb',
        abundance='data_lake/indexes/abundance.duckdb',
    output:
        'results/samplesheets/reference_genomes.csv'
    params:
        read_frac=config['mapping']['min_frac_ref'],
        read_pow=config['mapping']['min_pow_ref'],
    localrule: True
    envmodules:
        'duckdb/nightly'
    shell:
        '''
        export READ_FRAC={params.read_frac} READ_POW={params.read_pow}

        duckdb -readonly -init config/.duckdbrc {input.samples} \
          -c 'copy (select "sample", ID, taxon from samples) to "/dev/stdout" (format csv);' |\
        duckdb -readonly -init config/.duckdbrc {input.abundance} \
          -c '.read workflow/scripts/match_reference_genome.sql' > {output}
        '''