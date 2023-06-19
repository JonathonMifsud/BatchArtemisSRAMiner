#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# shell wrapper script to run the summary table script

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"
file_of_accessions=""

while getopts "p:q:r:f:" 'OPTKEY'; do
    case "$OPTKEY" in
        'p')
            project="$OPTARG"
            ;;
        '?')
            echo "INVALID OPTION -- ${OPTARG}" >&2
            exit 1
            ;;
        ':')
            echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
            exit 1
            ;;
        'q')
            queue="$OPTARG"
            ;;
        'r')
            root_project="$OPTARG"
            ;;
        'f')
            file_of_accessions="$OPTARG"
            ;;
    esac
done

    shift $(( OPTIND - 1 ))

    if [ "$project" = "" ]
        then
            echo "No project string entered. Use e.g, -p JCOM_pipeline_virome"
    exit 1
    fi

    if [ "$root_project" = "" ]
        then
            echo "No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    exit 1
    fi

    if [ "$file_of_accessions" = "" ]
        then
            echo "No accessions provided (-f), Summary table will generated using all accessions in /project/"$root_project"/"$project"/contigs/ /project/"$root_project"/"$project"/blast_results/ etc"
        else    
            file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

         # NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
    if [ "$queue" = "defaultQ" ]
        then 
            job_time="walltime=1:00:00"
            queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
    fi

qsub -o "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,root_project=$root_project,file_of_accessions=$file_of_accessions" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_summary_table.pbs