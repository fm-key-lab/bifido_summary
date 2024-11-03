-- TODO: Add comments as table metadata

create table sequencing as
select * exclude (ID)
    , ID as original_id
    , case when notes ilike '%failed%' then true 
           else false 
           end as failed
    -- NOTE: Fixes index swapping on library plate
    , case when notes ilike '%fastqID%' then regexp_extract(notes, 'fastqID_of_sample:(B001_\d+)$', 1) 
           else original_id 
           end as ID
from read_csv(
    getenv('SEQ_INFO'),
    columns = {
        'plate_id': varchar,
        'plate_well': varchar,
        'i5_name': varchar,
        'i7_name': varchar,
        'ID': varchar,
        'library_prep': varchar,
        'notes': varchar
    },
    skip = 14
) ;