# Analyze Bifido

## Usage

```bash
module load task
task -t $GROUP_HOME/tools/lab-tasks smk:run PROJ="bifido_summary" EXTRA=" -n"
```

```JSON
    "reference": {
      "Bifidobacterium_bifidum": "/nexus/posix0/MPIIB-keylab/public_data/reference_genomes/Bifidobacterium_bifidum/GCA_001025135.1/NCBI/ncbi_dataset/data/GCA_001025135.1/GCA_001025135.1_ASM102513v1_genomic.fna",
      "Cutibacterium_acnes": "/nexus/posix0/MPIIB-keylab/public_data/reference_genomes/Cutibacterium_acnes/GCF_000008345.1/NCBI/ncbi_dataset/data/GCF_000008345.1/GCF_000008345.1_ASM834v1_genomic.fna",
      "Enterococcus_faecium": "/nexus/posix0/MPIIB-keylab/public_data/reference_genomes/Enterococcus_faecium/GCF_016864255.1/NCBI/ncbi_dataset/data/GCF_016864255.1/GCF_016864255.1_ASM1686425v1_genomic.fna",
      "Staphylococcus_aureus": "/nexus/posix0/MPIIB-keylab/public_data/reference_genomes/Staphylococcus_aureus/GCA_024178405.1/NCBI/ncbi_dataset/data/GCA_024178405.1/GCA_024178405.1_ASM2417840v1_genomic.fna"
    }

	"wildcards": {
		"donors": "B001",
		"relationships": "F|M|B",
		"species": "Bifidobacterium_adolescentis|Bifidobacterium_bifidum|Bifidobacterium_longum"
	},
	"wildcards": {
		"donors": "B001",
		"relationships": "F|M|B",
		"species": "Bifidobacterium_adolescentis|Bifidobacterium_bifidum|Bifidobacterium_longum|Enterococcus_faecalis|Escherichia_coli|Staphylococcus_aureus",
		"time_cat": "vor|2Wochen|4Wochen"
	},

```