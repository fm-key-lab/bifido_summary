rule hive_partition_vcfs:
    input:
        ancient('results/{species}/variants/{sample}.vcf.gz'),
    output:
        'data_lake/logs/vcfs.species={species}.sample={sample}.done'
    params:
        prefix='data_lake/variants/species={species}/sample={sample}'
    resources:
        cpus_per_task=4,
        runtime=5
    envmodules:
        'bcftools/1.20',
        'vcf2parquet/0.4.1'
    shell:
        '''
        for indel in 0 1; do
          for dp in 2 3 4 5 6 7; do
            output="{params.prefix}/INDEL=$indel/DP=$dp/vcf.parquet"

            mkdir -p $(dirname $output)
            
            bcftools view -i 'INFO/INDEL='"$indel"' & (SUM(INFO/ADF)<'"$((dp+1))"' | SUM(INFO/ADR)<'"$((dp+1))"') & SUM(INFO/ADF)>='"$dp"' & SUM(INFO/ADR)>='"$dp" {input} |\
              vcf2parquet -i /dev/stdin convert -o "{params.prefix}/INDEL=$indel/DP=$dp/data.parquet"
          done
        done

        touch {output} # Not source why using `touch()` in output not working ...
        '''


def candidate_variant_tables(wildcards):
    import pandas as pd

    sample_ids = (
        pd.read_csv(
            checkpoints.mapping_samplesheet.get(
                species=wildcards.species
            ).output[0]
        )
        ['sample']
    )

    return expand(
        'data_lake/logs/vcfs.species={{species}}.sample={sample}.done',
        sample=sample_ids
    )


rule:
    input:
        candidate_variant_tables
    output:
        touch('logs/cmt.{species}.done')
    localrule: True


# rule create_variants_db:
#     input:
#         expand(
#             'logs/cmt.{species}.done',
#             species=config['wildcards']['species'].split('|')
#         )
#     output:
#         'results/candidate_variants.duckdb',
#     params:
#         vcfs="'results/lake/*/*/nonindels.parquet'",
#     resources:
#         cpus_per_task=32,
#         mem_mb=96_000,
#         runtime=90
#     envmodules:
#         'duckdb/nightly'
#     shell:
#         '''
#         export MEMORY_LIMIT="$(({resources.mem_mb} / 1200))GB" \
#                VCFS={params.vcfs}
        
#         duckdb {output} -c ".read workflow/scripts/create_variants_db.sql"
#         '''