copy (
    select 
        samples.sample
        , columns('fastq_[1,2]')
    from read_csv(
        getenv('FASTQS')
    ) fastqs, samples
    where samples.ID = fastqs.ID
    order by samples.sample
) to '/dev/stdout' (format csv);