set memory_limit = getenv('MEMORY_LIMIT');
set threads = getenv('SLURM_CPUS_PER_TASK');

create table samplesheet as
select samples.*, fastqs.fastq_1, fastqs.fastq_2 
from fastqs, samples 
where fastqs.ID = samples.ID 
order by samples.ID;

drop table samples;
drop table fastqs;