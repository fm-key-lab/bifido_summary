set memory_limit = getenv('MEMORY_LIMIT');
set threads = getenv('SLURM_CPUS_PER_TASK');

create type family_relationship as enum ('F', 'M', 'B');

create table relationship_ref (
    relationship_raw varchar,
    relationship family_relationship
);

insert into relationship_ref (relationship_raw, relationship) 
values 
    ('Vater', 'F'), 
    ('Mutter', 'M'), 
    ('Baby', 'B');

create type bacteria_taxon as enum (
    'Bacteroides_xylanisolvens',
    'Bifidobacterium_adolescentis',
    'Bifidobacterium_bifidum',
    'Bifidobacterium_breve',
    'Bifidobacterium_longum',
    'Bifidobacterium_spp',
    'Cutibacterium_acnes',
    'Enterococcus_faecalis',
    'Enterococcus_faecium',
    'Escherichia_coli',
    'Klebsiella_oxytoca',
    'Lactococcus_lactis',
    'Staphylococcus_aureus'
);

create table taxon_ref (
    taxon_raw varchar,
    taxon bacteria_taxon
);

insert into taxon_ref (taxon_raw, taxon) 
values 
    ('Bacteroides_xylanisolvens', 'Bacteroides_xylanisolvens'), 
    ('Bifidobacterium_adolescentis', 'Bifidobacterium_adolescentis'),
    ('Bifidobacterium_bifidum', 'Bifidobacterium_bifidum'),
    ('Bifidobacterium_breve', 'Bifidobacterium_breve'),
    ('Bifidobacterium_longum', 'Bifidobacterium_longum'),
    ('Bifidobacterium_spp', 'Bifidobacterium_spp'),
    ('Cutibacterium_acnes', 'Cutibacterium_acnes'),
    ('Enterococcus_faecalis', 'Enterococcus_faecalis'),
    ('Enterococcus_faecium', 'Enterococcus_faecium'),
    ('Escherichia_coli', 'Escherichia_coli'),
    ('Escherichia_coli_(rot)', 'Escherichia_coli'),
    ('Escherichia_coli_(weiß)', 'Escherichia_coli'),
    ('Klebsiella_oxytoca', 'Klebsiella_oxytoca'),
    ('Lactococcus_lactis', 'Lactococcus_lactis'),
    ('Staphylococcus_aureus', 'Staphylococcus_aureus');

create table date_ref (
    time_cat varchar,
    time_weeks varchar
);

insert into date_ref (time_cat, time_weeks) 
values 
    ('vor', -2), 
    ('2Wochen', 2), 
    ('4Wochen', 4), 
    ('2Monate', 8), 
    ('3Monate', 13), 
    ('6Monate', 26);
