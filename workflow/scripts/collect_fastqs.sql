copy (
    with fastqs as (
        select "file"
            , regexp_extract(
                "file",
                getenv('PAT'),
                ['library', 'ID', 'read']
            ) as info
        from glob(getenv('GLOB'))
        -- NOTE: Controls are dropped.
        where "file" not ilike '%plate%'
    )
    select * 
    from (
        pivot (
            select "file"
                , info.* exclude ("read")
                , 'fastq_' || info.read as "read"
            from fastqs
        ) 
        on "read" 
        using first("file") 
        group by library, ID
    )
) to '/dev/stdout' (format csv);