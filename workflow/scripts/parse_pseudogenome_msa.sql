set memory_limit = getenv('MEMORY_LIMIT');

-- Single-threading ensures deterministict sampling, given seed
set threads = 1;

-- Ensure stdout not polluted
set enable_progress_bar = false;

-- Filter variants
create temp table filtered_vars as
select * from candidate_variant_tbl
where strlen("ref") = 1
  and strlen(alt) = 1
  and alt_fwd_dp >= 3
  and alt_rev_dp >= 3
  and dp >= 5
  and maf >= .95
  and qual >= 30
;

-- Filter samples
create temp table filtered_samples as
select distinct("sample") as "sample"
from candidate_variant_tbl;

-- Create pseudoreference
create temp table pseudoref as
select * from (
    select chrom, chrom_pos, ref
    from filtered_vars
    group by chrom, chrom_pos, ref
    having count(ref) > 1
)
using sample reservoir(10000 rows) repeatable (10023);

-- Create output table
create temp table output_tbl as
with filtered_refs as (
    select *
    from filtered_samples
    cross join pseudoref
)
select 
    cast(r.sample as varchar) as "sample"
    , r.chrom
    , r.chrom_pos
    , r.ref
    , a.alt
    , coalesce(a.alt, r.ref) as allele
from filtered_refs r
left join filtered_vars a
       on r.sample = a.sample
      and r.chrom = a.chrom
      and r.chrom_pos = a.chrom_pos
;

-- Use reference as outgroup
alter table pseudoref add column "sample" varchar default 'outgroup';
alter table pseudoref add column alt varchar;
alter table pseudoref add column allele varchar;
update pseudoref set allele = "ref";

insert into output_tbl 
select "sample", chrom, chrom_pos, ref, alt, allele from pseudoref;

-- Add sample info
attach '/ptmp/thosi/bifido_summary/results/samplesheet.duckdb' as samplesheet_db;

create table output_10k as
select o.*, s.ID, s.taxon, s.relationship, s.time_weeks
from output_tbl o, (
    select ID, taxon, relationship, time_weeks, cast("sample" as varchar) as "sample"
    from samplesheet_db.samplesheet
) s
where s.sample = o.sample;

-- Output as FASTA

-- Combined
copy (
    select 
        '>' || "ID" || chr(10) || string_agg(ifnull(allele, '-'), '')
    from output_10k
    group by "ID"
    order by "ID"
) to '/u/thosi/dev/tmp/bifido_v02.fas' (delimiter '', header false, quote '');