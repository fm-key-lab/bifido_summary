rule bcftools_query:
    input:
        'results/{species}/variants/{sample}.vcf.gz',
    output:
        'results/{species}/variants/{sample}_af.tsv'
    resources:
        cpus_per_task=2,
        runtime=5
    envmodules:
        'bcftools/1.20'
    shell:
        '''
        bcftools +fill-tags {input} -- -t AF | \
        bcftools query -f '%CHROM\t%POS\t%REF\t%ALT[\t%SAMPLE]\t%QUAL\t%DP\t%INFO/DP4\n' > {output}
        '''


def candidate_variant_tables(wildcards):
    import pandas as pd

    ref_genomes = pd.read_csv(
        checkpoints.reference_genomes.get(
            **wildcards
        ).output[1]
    )

    ref_genomes = ref_genomes[
        ~ref_genomes['sample'].astype(int).isin(EXCLUDE)
    ]

    return list(
        ref_genomes
        [ref_genomes['taxon'].isin(config['wildcards']['species'].split('|'))]
        .filter(['sample', 'taxon'])
        .rename(columns={'taxon': 'species'})
        .drop_duplicates()
        .transpose()
        .apply(lambda df: 'results/{species}/variants/{sample}_af.tsv'.format(**df.to_dict()))
        .values
        .flatten()
    )


rule create_variants_db:
    input:
        candidate_variant_tables
    params:
        af_glob="'results/*/variants/*_af.tsv'",
    output:
        'results/all_variants.duckdb',
    resources:
        cpus_per_task=32,
        mem_mb=48_000,
        runtime=30
    envmodules:
        'duckdb/nightly'
    shell:
        '''
        export MEMORY_LIMIT="$(({resources.mem_mb} / 1000))GB" \
               BCFTOOLS_QUERY={params.af_glob}
        
        duckdb {output} -c ".read workflow/scripts/create_variants_db.sql"
        '''