checkpoint mapping_samplesheet:
    input:
        ancient('results/samplesheet.csv'),
        ancient('results/reference_genomes.csv')
    output:
        'results/{species}/mapping_samplesheet.csv'
    localrule: True
    run:
        import pandas as pd

        samplesheet = pd.read_csv(input[0])
        ref_genomes = pd.read_csv(input[1])
        
        mapping_samplesheet = (
            ref_genomes
            [ref_genomes['taxon'] == wildcards.species]
            .merge(samplesheet, on='sample')
            .filter(['sample', 'fastq_1', 'fastq_2'])
        )

        mapping_samplesheet = mapping_samplesheet[
            ~mapping_samplesheet['sample'].astype(int).isin(EXCLUDE)
        ]

        mapping_samplesheet.to_csv(output[0], index=False)


use rule bactmap from widevariant as mapping with:
    input:
        input=ancient('results/{species}/mapping_samplesheet.csv'),
        reference=lambda wildcards: config['public_data']['reference'][wildcards.species],
    params:
        pipeline='bactmap',
        profile='singularity',
        nxf='-work-dir results/{species}/work -config ' + config['bactmap_cfg'],
        outdir='results/{species}',
    output:
        'results/{species}/pipeline_info/pipeline_report.txt',
        'results/{species}/multiqc/multiqc_data/multiqc_fastp.yaml',
    localrule: True
    envmodules:
        'apptainer/1.3.2',
        'nextflow/21.10',
        'jdk/17.0.10'


rule collect_vcfs:
    """Collect mapping output.
    
    Collect mapping output such that the sample wildcard can be
    resolved by downstream rules.
    """
    input:
        ancient('results/{species}/pipeline_info/pipeline_report.txt'),
    output:
        touch('results/{species}/variants/{sample}.vcf.gz'),
    localrule: True