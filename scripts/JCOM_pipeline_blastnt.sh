#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# This script will run blastn on .contigs.fa files from the final_contigs folder
# It will then extract the contigs that have a blast hit to the nr database

# I tend to run this once per project on a single file containing all the contigs concatenated together resulting from the Rdrp and RVDB blasts (i.e. the blastcontig.fa files in blast_results/)

# provide a file containing SRA accessions - make sure it is full path to file -f

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"

show_help() {
    echo ""
    echo "Usage: $0 [-f file_of_accessions] [-d db] [-h]"
    echo "  -f file_of_accessions: Full path to text file containing library ids one per line. (Required)"
    echo "  -d db: Blast+ Database for blastn. (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "  Example:"
    echo "  $0 -f /project/$root_project/$project/accession_lists/mylibs.txt -d /scratch/VELAB/Databases/Blast/nt.^MONTH^-^YEAR^/nt"
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "p:f:q:r:d:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'p')
        #
        project="$OPTARG"
        ;;
    'f')
        #
        file_of_accessions="$OPTARG"
        ;;
    'q')
        #
        queue="$OPTARG"
        ;;
    'r')
        #
        root_project="$OPTARG"
        ;;
    'd')
        #
        db="$OPTARG"
        ;;
    'h')
        #
        show_help
        ;;        
    '?')
        echo "INVALID OPTION -- ${OPTARG}" >&2
        show_help
        ;;
    ':')
        echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
        show_help
        ;;
    *)
        # Handle invalid flags here
        echo "Invalid option: -$OPTARG" >&2
        show_help
        ;;    
    esac
done
shift $((OPTIND - 1))

if [ "$project" = "" ]; then
    echo "ERROR: No project string entered. Use e.g, -p JCOM_pipeline_virome"
    show_help
fi

if [ "$root_project" = "" ]; then
    echo "ERROR: No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    show_help
fi

if [ "$db" = "" ]; then
    echo "ERROR: No database specified. Use e.g., -d /scratch/VELAB/Databases/Blast/nt.Jul-2023/nt"
    show_help
fi

if [ "$file_of_accessions" = "" ]; then
    echo "ERROR: No accession file containing files to run specified, please specify this with -f"
    show_help
else
    export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

if [ "$queue" = "defaultQ" ]; then
    echo "Queue set to defaultQ"
fi

# NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
if [ "$queue" = "defaultQ" ]; then
    job_time="walltime=120:00:00"
    queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
    cpu="ncpus=24"
    mem="mem=220GB"
    blast_cpu="24"
    blast_para="-max_target_seqs 10 -num_threads $cpu -mt_mode 1 -evalue 1E-10 -subject_besthit -outfmt '6 qseqid qlen sacc salltitles staxids pident length evalue'"
fi

if [ "$queue" = "intensive" ]; then
    job_time="walltime=124:00:00"
    queue_project="VELAB"
    queue="defaultQ"
    cpu="ncpus=24"
    mem="mem=220GB"
    blast_cpu="24"
    blast_mem="8"
    blast_para="-max_target_seqs 10 -num_threads $cpu -mt_mode 1 -evalue 1E-10 -subject_besthit -outfmt '6 qseqid qlen sacc salltitles staxids pident length evalue'"
fi

qsub -o "/project/$root_project/$project/logs/blastnt_$project_$queue_$db_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/blastnt_$project_$queue_$db_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,blast_para=$blast_para,cpu=$cpu,db=$db" \
    -q "$queue" \
    -l "$job_time" \
    -l "$cpu" \
    -l "$mem" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_blastnt.pbs
