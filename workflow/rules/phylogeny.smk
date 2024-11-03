rule pseudogenome_alignment:
    input:
        ancient('results/candidate_variants.duckdb'),
    output:
        'results/aligned_pseudogenomes/FAMILY={donor}/SPECIES={species}.variants.csv',
        'results/aligned_pseudogenomes/FAMILY={donor}/SPECIES={species}.fas',
    params:
        alt=config['variants_thresh']['reads_alt'],
        covg=config['variants_thresh']['coverage'],
        maf=config['variants_thresh']['maf'],
        qual=config['variants_thresh']['qual'],
    resources:
        cpus_per_task=32,
        mem_mb=96_000,
        runtime=15,
    envmodules:
        'duckdb/nightly'
    shell:
        '''
        export MEMORY_LIMIT="$(({resources.mem_mb} / 1100))GB" \
               DP={params.covg} \
               MAF={params.maf} \
               QUAL={params.qual} \
               SPECIES={wildcards.species} \
               STRAND_DP={params.alt}
        
        duckdb -readonly {input} -c ".read workflow/scripts/parse_variants.sql" > {output[0]}

        cat {output[0]} |\
          duckdb -c ".read workflow/scripts/to_msa.sql" > {output[1]}
        '''


rule filter_invariant_sites:
    input:
        'results/aligned_pseudogenomes/FAMILY={donor}/SPECIES={species}.fas',
    output:
        'results/aligned_pseudogenomes/FAMILY={donor}/SPECIES={species}-filtered.fas',
    localrule: True
    envmodules:
        'snp-sites/2.5.1'
    shell:
        '''
        snp-sites -o {output} {input}
        '''


rule raxml_ng:
    input:
        'results/aligned_pseudogenomes/FAMILY={donor}/SPECIES={species}-filtered.fas',
    params:
        extra='--all --model GTR+G --bs-trees 200',
        # outgroup=lambda wildcards: '--outgroup ' + config['outgroup'][wildcards.donor][wildcards.species]['ID'],
        outgroup='',
        prefix='results/raxml_ng/FAMILY={donor}/SPECIES={species}',
    output:
        multiext(
            'results/raxml_ng/FAMILY={donor}/SPECIES={species}.raxml',
            '.reduced.phy',
            '.rba',
            '.bestTreeCollapsed',
            '.bestTree',
            '.mlTrees',
            '.support',
            '.bestModel',
            '.bootstraps',
            '.log'
        )
    resources:
        cpus_per_task=48,
        mem_mb=64_000,
        runtime=120,
    envmodules:
        'raxml-ng/1.2.2_MPI'
    shell:
        '''
        export OMP_PLACES=threads
        raxml-ng \
          {params.extra} \
          {params.outgroup} \
          --msa {input} \
          --threads {resources.cpus_per_task} \
          --prefix {params.prefix} \
          --redo
        touch {output}
        '''


def trees_output(wildcards):
    import pandas as pd

    donor_list = config['wildcards']['donors'].split('|')
    
    species_list = config['wildcards']['species'].split('|')

    matched_donors = (
        pd.read_csv(
            checkpoints.samplesheet.get(
                **wildcards
            ).output[0]
        )
        .query('donor == @donor_list')
        .filter(['sample', 'donor'])
        .drop_duplicates()
    )
    
    matched_species = (
        pd.read_csv(
            checkpoints.reference_genomes.get(
                **wildcards
            ).output[1]
        )
        .rename(columns={'taxon': 'species'})
        .query('species == @species_list')
        .filter(['sample', 'species'])
        .drop_duplicates()
    )

    return list(
        matched_donors
        .merge(matched_species)
        .assign(sample=lambda df: df.pop('sample').astype(int))
        .query('sample != @EXCLUDE')
        .query('sample != @INDEX_SWAPPED')
        .drop_duplicates()
        .transpose()
        .apply(lambda df: 'results/raxml_ng/FAMILY={donor}/SPECIES={species}.raxml.bestTree'.format(**df.to_dict()))
        .values
        .flatten()
    )


rule:
    input:
        trees_output
    output:
        touch('results/phylogenies.done')
    localrule: True