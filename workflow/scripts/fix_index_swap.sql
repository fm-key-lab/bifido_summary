copy (
    select
        regexp_replace(seq.ID, '_', '-') as ID
        , columns('fastq_[1,2]')
    from (
        select * from read_csv(getenv('FASTQS'))
    ) fastqs, sequencing seq
    where
        regexp_replace(fastqs.ID, '-', '_') = seq.original_id
) to '/dev/stdout' (format csv);