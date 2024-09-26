set memory_limit = getenv('MEMORY_LIMIT');
set threads = getenv('SLURM_CPUS_PER_TASK');

create table fastqs as
pivot (
    select 
        struct_extract(ID_read, 'ID') as ID
        , "file"
        , 'fastq_' || struct_extract(ID_read, 'read') as "read"
    from (
        select
            "file" 
            , regexp_extract(
                "file",
                'mpimg_L\d+-\d_(B001-\d+)_S\d+_R(1|2)_001.fastq.gz',
                ['ID', 'read']
            ) as ID_read
        from glob(getenv('FASTQS_DIR'))
    )
    where strlen(ID) > 0
) on "read" using first("file") group by ID;