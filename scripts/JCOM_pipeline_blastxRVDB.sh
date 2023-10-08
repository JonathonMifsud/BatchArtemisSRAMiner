#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run blastx against the RVDB database
# provide a file containing the names of the read files to run only one per library! example only the first of the pairs
# if you do not provide it will use thoes in $project trimmed_reads

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"

while getopts "p:f:q:r:d:" 'OPTKEY'; do
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
    '?')
        echo "INVALID OPTION -- ${OPTARG}" >&2
        exit 1
        ;;
    ':')
        echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
        exit 1
        ;;
    *)
        # Handle invalid flags here
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;    
    esac
done
shift $((OPTIND - 1))

if [ "$project" = "" ]; then
    echo "No project string entered. Use e.g, -p JCOM_pipeline_virome"
    exit 1
fi

if [ "$root_project" = "" ]; then
    echo "No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    exit 1
fi

if [ "$file_of_accessions" = "" ]; then
    echo "No file containing files to run specified running all files in /project/$root_project/$project/contigs/final_contigs/"
    ls -d /project/"$root_project"/"$project"/contigs/final_contigs/*.fa >/project/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_blastx_RVDB
    export file_of_accessions="/project/$root_project/$project/contigs/final_contigs/file_of_accessions_for_blastx_RVDB"
else
    export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

#lets work out how many jobs we need from the length of input and format the J phrase for the pbs script
jMax=$(wc -l <"$file_of_accessions")
jIndex=$(expr "$jMax" - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

# NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
if [ "$queue" = "defaultQ" ]; then
    job_time="walltime=84:00:00"
    queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
fi

if [ "$db" = "" ]; then
    echo "No database specified. Use -d option to specify the database, please check the databse folder for newer verisons but for e.g, -d /scratch/VELAB/Databases/Blast/RVDB/U-RVDBv22.0-prot-exo_curated.dmnd"
    exit 1
fi

qsub -J "$jPhrase" \
    -o "/project/$root_project/$project/logs/blastxRVDB_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/blastxRVDB_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,db=$db" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_blastxRVDB.pbs
