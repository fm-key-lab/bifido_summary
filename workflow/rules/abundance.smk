def paired_fastqs(wildcards):
    import pandas as pd

    return (
        pd.read_csv(
            checkpoints.samplesheet.get(**wildcards).output[1]
        )
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


def species_abundance_output(wildcards):
    import pandas as pd

    sample_ids = (
        pd.read_csv(
            checkpoints.samplesheet.get(
                **wildcards
            ).output[1]
        )
        ['sample'].astype(str)
    )

    return expand(
        [
            'results/bracken/{sample}.bracken',
            'results/bracken/{sample}.breport',
        ],
        sample=sample_ids
    )


checkpoint reference_genomes:
    input:
        species_abundance_output
    params:
        bracken_glob="'results/bracken/*.bracken'"
    output:
        'results/abundance.duckdb',
        'results/reference_genomes.csv'
    resources:
        cpus_per_task=8,
        mem_mb=4_000,
        runtime=15
    envmodules:
        'duckdb/nightly'
    shell:
        '''
        export MEMORY_LIMIT="$(({resources.mem_mb} / 1000))GB" \
               BRACKEN_GLOB={params.bracken_glob}
        
        duckdb -init workflow/scripts/create_abundance_db.sql {output[0]} \
            -c ".read workflow/scripts/parse_abundance_taxa.sql"

        duckdb -csv -init workflow/scripts/parse_abundance_taxa.sql {output[0]} \
            -c "set enable_progress_bar = false; copy reference_genomes to '/dev/stdout';" > {output[1]}
        '''