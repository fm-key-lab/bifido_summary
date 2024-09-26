set memory_limit = getenv('MEMORY_LIMIT');
set threads = getenv('SLURM_CPUS_PER_TASK');

create type bacteria_taxon as enum (
    'Bacteroides_xylanisolvens',
    'Bifidobacterium_adolescentis',
    'Bifidobacterium_bifidum',
    'Bifidobacterium_breve',
    'Bifidobacterium_longum',
    'Bifidobacterium_spp',
    'Cutibacterium_acnes',
    'Enterococcus_faecalis',
    'Enterococcus_faecium',
    'Escherichia_coli',
    'Klebsiella_oxytoca',
    'Lactococcus_lactis',
    'Staphylococcus_aureus'
);

create table taxon_ref (
    taxon_raw varchar,
    taxon bacteria_taxon
);

insert into taxon_ref (taxon_raw, taxon) 
values 
    ('Bacteroides_xylanisolvens', 'Bacteroides_xylanisolvens'), 
    ('Bifidobacterium_adolescentis', 'Bifidobacterium_adolescentis'),
    ('Bifidobacterium_bifidum', 'Bifidobacterium_bifidum'),
    ('Bifidobacterium_breve', 'Bifidobacterium_breve'),
    ('Bifidobacterium_longum', 'Bifidobacterium_longum'),
    ('Bifidobacterium_spp', 'Bifidobacterium_spp'),
    ('Cutibacterium_acnes', 'Cutibacterium_acnes'),
    ('Enterococcus_faecalis', 'Enterococcus_faecalis'),
    ('Enterococcus_faecium', 'Enterococcus_faecium'),
    ('Escherichia_coli', 'Escherichia_coli'),
    ('Escherichia_coli_(rot)', 'Escherichia_coli'),
    ('Escherichia_coli_(weiß)', 'Escherichia_coli'),
    ('Klebsiella_oxytoca', 'Klebsiella_oxytoca'),
    ('Lactococcus_lactis', 'Lactococcus_lactis'),
    ('Staphylococcus_aureus', 'Staphylococcus_aureus');

-- TODO: Use info from sample sheet?

create table reference_genomes as
with obs_taxon as (
    select *, regexp_replace(trim(abundance.name), ' ', '_', 'g') as taxon_raw
    from abundance 
    inner join (
        select 
            "sample"
            , max(fraction_total_reads) as max_frac 
        from abundance 
        where "name" != 'Homo sapiens'
        group by "sample"
    ) obs_max 
    on 
        abundance.sample = obs_max.sample 
    and abundance.fraction_total_reads = obs_max.max_frac 
)
select 
    "sample"
    , try_cast(
        coalesce(
            taxon_ref.taxon, obs_taxon.taxon_raw
        ) as bacteria_taxon
    ) as taxon
from obs_taxon
left join taxon_ref
on taxon_ref.taxon_raw = obs_taxon.taxon_raw;