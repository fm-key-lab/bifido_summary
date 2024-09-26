rule pseudogenome_alignment:
    input:
        samplesheet='results/samplesheet.csv',
        db='results/{species}/variants/candidate_variants.duckdb',
    params:
        alt=config['variants_thresh']['reads_alt'],
        covg=config['variants_thresh']['coverage'],
        idist=config['variants_thresh']['interpos_dist'],
        maf=config['variants_thresh']['maf'],
        qual=config['variants_thresh']['qual'],
    output:
        'results/{species}/aligned_pseudogenomes/{donor}/{relationship}/{time}.fas',
    resources:
        cpus_per_task=1,
        mem_mb=64_000,
        runtime=30,
    envmodules:
        'duckdb/nightly'
    shell:
        '''
        export MEMORY_LIMIT="$(({resources.mem_mb} / 1100))GB" \
               ALT_STRAND_DP_THRESHOLD={params.alt} \
               COVERAGE_THRESHOLD={params.covg} \
               INTERBASE_DISTANCE_THRESHOLD={params.idist} \
               MAF_THRESHOLD={params.maf} \
               QUAL_THRESHOLD={params.qual} \
               SAMPLESHEET={input.samplesheet} \
               DONOR={wildcards.donor} \
               RELATIONSHIP={wildcards.relationship} \
               TIME_CAT={wildcards.time}
        duckdb -readonly {input.db} -c ".read workflow/scripts/finalize_variants.sql" > {output}
        '''


rule extract_variant_sites:
    input:
        'results/{species}/aligned_pseudogenomes/{donor}/{relationship}/{time}.fas',
    output:
        'results/{species}/snpsites/{donor}/{relationship}/{time}.filtered_alignment.fas',
    localrule: True
    envmodules:
        'snp-sites/2.5.1'
    shell:
        '''
        snp-sites -o {output} {input}
        '''


rule veryfasttree:
    """Run VeryFastTree.

    Build a phylogeny from the multiple sequence alignment using the 
    VeryFastTree implementation of the FastTree-2 algorithm.

    Args:

    Returns:
    
    Notes:
      - [GitHub](https://github.com/citiususc/veryfasttree)
    """
    input:
        'results/{species}/snpsites/{donor}/{relationship}/{time}.filtered_alignment.fas',
    params:
        extra='-double-precision -nt'
    output:
        'results/{species}/veryfasttree/{donor}/{relationship}/{time}_complete.veryfasttree.phylogeny.nhx',
    resources:
        cpus_per_task=32,
        mem_mb=64_000,
        runtime=30,
    envmodules:
        'veryfasttree/4.0.3.1'
    shell:
        '''
        export OMP_PLACES=threads
        (veryfasttree {input} {params.extra} -threads {resources.cpus_per_task} > {output}) || touch {output}
        '''


# TODO: Add outgroup here

rule raxml_ng:
    """Run RAxML-NG.

    Build a maximum-likelihood phylogeny from the multiple sequence alignment 
    using RAxML Next Generation.

    Args:

    Returns:
      {{ prefix }}.raxml.reduced.phy: Reduced alignment (with duplicates 
        and gap-only sites/taxa removed)
      {{ prefix }}.raxml.rba: Binary MSA file
      {{ prefix }}.raxml.bestTreeCollapsed: Best ML tree with collapsed near-zero branches
      {{ prefix }}.raxml.bestTree: Best ML tree
      {{ prefix }}.raxml.mlTrees: All ML trees
      {{ prefix }}.raxml.support: Best ML tree with Felsenstein bootstrap (FBP) support
      {{ prefix }}.raxml.bestModel: Optimized model
      {{ prefix }}.raxml.bootstraps: Bootstrap trees
      {{ prefix }}.raxml.log: Execution log
    
    Notes:
      - [GitHub](https://github.com/amkozlov/raxml-ng)
    """
    input:
        'results/{species}/snpsites/{donor}/{relationship}/{time}.filtered_alignment.fas',
    params:
        extra='--all --model GTR+G --bs-trees 200',
        prefix='results/{species}/raxml_ng/{donor}/{relationship}/{time}_complete',
    output:
        multiext(
            'results/{species}/raxml_ng/{donor}/{relationship}/{time}_complete.raxml',
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
        raxml-ng {params.extra} --msa {input} --threads {resources.cpus_per_task} --prefix {params.prefix} --redo
        # `reduced.phy` may not be generated after SNP-Sites' `raxml.mlTrees`, etc. not generated unless bootstraping
        touch {output}
        '''


def trees_output(wildcards):
    import pandas as pd

    samplesheet = pd.read_csv(
        checkpoints.samplesheet.get(
            **wildcards
        ).output[0]
    )

    tree_output = list(
        samplesheet[
            samplesheet['species'].isin('Bifidobacterium_spp'.split('|'))
            & samplesheet['donor'].isin('B001'.split('|'))
            & samplesheet['relationship'].isin('Vater|Mutter|Baby'.split('|'))
            & samplesheet['time_cat'].isin('vor|2Wochen|4Wochen'.split('|'))
        ]
        # TODO: Dynamically parse MSAs that shouldn't be used for trees
        [
            ~(
                (samplesheet['species'] == 'Bifidobacterium_spp') 
                & (samplesheet['donor'] == 'B001') 
                & (samplesheet['relationship'] == 'Vater') 
                & (samplesheet['time_cat'] == '4Wochen')
            )
        ]
        .filter(['species', 'donor', 'relationship', 'time_cat'])
        .drop_duplicates()
        .transpose()
        .apply(
            lambda df: [output.format(**df.to_dict()) for output in [
                'results/{species}/veryfasttree/{donor}/{relationship}/{time_cat}_complete.veryfasttree.phylogeny.nhx',
                'results/{species}/raxml_ng/{donor}/{relationship}/{time_cat}_complete.raxml.bestTree'
            ]]
        )
        .values
        .flatten()
    )

    return tree_output


rule:
    input:
        trees_output
    output:
        touch('results/phylogenies_complete.done')
    localrule: True