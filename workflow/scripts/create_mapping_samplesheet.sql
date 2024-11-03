-- export FASTQS=data_lake/indexes/fastqs.csv
-- duckdb data_lake/indexes/samples.duckdb

-- TODO: Must run after kraken2 labeling

select
    samples.sample
    , columns('fastq_[1,2]')
from (
    select * from read_csv(getenv('FASTQS'))
) fastqs, samples
where fastqs.ID = samples.ID
order by samples.sample;