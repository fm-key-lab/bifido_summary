set memory_limit = getenv('MEMORY_LIMIT');
set threads = getenv('SLURM_CPUS_PER_TASK');

load spatial;

create table samples as 
with combined_tmp as (
    select * exclude(taxon_raw)
        , regexp_replace(trim(taxon_raw), ' ', '_', 'g') as taxon_raw
    from (
        select "gDNA from 96-Well" as ID
            , Field2 as taxon_raw
            , regexp_extract(Field3, '^(\D+)-', 1) as relationship_raw
            , regexp_extract(Field3, '-(\w+)$', 1) as time_cat
        from st_read(
            getenv('SAMPLESHEET'),
            layer = 'LibraryPlate1-3',
            open_options = ['HEADERS=FORCE']
        )
        union by name
        select
            Field1 as ID
            , Field2 as gDNA
            , case when Field4 is null then Field3
                else concat(Field3, ' (', Field4, ')')
                end as taxon_raw
            , Field5
            , Field6 as relationship_raw
            , Field7 as time_cat
        from st_read(
            getenv('SAMPLESHEET'),
            layer = 'LibraryPlate4-8'
        )
    )
    where ID is not null
    order by ID
)
select
    row_number() over () as "sample"
    , regexp_replace(samples.ID, '_', '-') as ID
    , regexp_extract(samples.ID, '([BP]\d+|Ctr\d+|Control\d+)_\d+', 1) as donor
    , try_cast(
        coalesce(
            t_ref.taxon, samples.taxon_raw
        ) as bacteria_taxon
    ) as taxon
    , try_cast(
        coalesce(
            r_ref.relationship, samples.relationship_raw
        ) as family_relationship
    ) as relationship
    , try_cast(
        coalesce(
            d_ref.time_weeks, samples.time_cat
        ) as smallint
    ) as time_weeks
from combined_tmp as samples
left join relationship_ref as r_ref
on r_ref.relationship_raw = samples.relationship_raw
left join taxon_ref as t_ref
on t_ref.taxon_raw = samples.taxon_raw
left join date_ref as d_ref
on d_ref.time_cat = samples.time_cat;