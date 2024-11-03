checkpoint mapping_samplesheet:
    input:
        'data_lake/indexes/fastqs.csv',
        'results/samplesheets/reference_genomes.csv',
    output:
        'results/{species}/samplesheet.csv',
    localrule: True
    run:
        import pandas as pd

        fastqs, ref_genomes = pd.read_csv(input[0]), pd.read_csv(input[1])
        
        (
            ref_genomes
            [ref_genomes['species'] == wildcards.species]
            .merge(fastqs, on='ID')
            .filter(['sample', 'fastq_1', 'fastq_2'])
            .to_csv(output[0], index=False)
        )


use rule bactmap from widevariant as mapping with:
    input:
        input='results/{species}/samplesheet.csv',
        reference=lambda wildcards: config['public_data']['reference'][wildcards.species],
    output:
        'results/{species}/pipeline_info/pipeline_report.txt',
        'results/{species}/multiqc/multiqc_data/multiqc_fastp.yaml',
    params:
        pipeline='bactmap',
        profile='singularity',
        nxf='-work-dir results/{species}/work -config ' + config['bactmap_cfg'],
        outdir='results/{species}',
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
        'results/{species}/pipeline_info/pipeline_report.txt',
    output:
        touch('results/{species}/variants/{sample}.vcf.gz'),
    localrule: True