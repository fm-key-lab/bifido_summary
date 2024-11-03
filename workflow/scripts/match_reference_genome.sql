create temp table joined as
select 
    a.sample
    , s.ID
    , a.name
    , a.new_est_reads
    , a.fraction_total_reads
from read_csv('/dev/stdin') s
inner join abundance a
    on s.sample = a.sample
where (s.taxon = 'Enterococcus_faecalis' and a.name ilike 'Enterococcus%')
   or (s.taxon = 'Escherichia_coli' and a.name ilike 'Escherichia%')
   or (s.taxon = 'Staphylococcus_aureus' and a.name ilike 'Staphylococcus%')
   or (s.taxon = 'Bifidobacterium_spp' and a.name ilike 'Bifidobacterium%')
;

copy (
    select 
        "sample"
        , ID
        , regexp_replace(
            trim("name"), ' ', '_', 'g'
        ) as species
        , new_est_reads
        , fraction_total_reads
    from joined
    where ("sample", fraction_total_reads) in (
        select ("sample", max(fraction_total_reads)) 
        from joined
        where new_est_reads > pow(10, cast(getenv('READ_POW') as int))
        and fraction_total_reads > cast(getenv('READ_FRAC') as float)
        group by "sample"
    )
    order by cast("sample" as int)
) to '/dev/stdout' (format csv);