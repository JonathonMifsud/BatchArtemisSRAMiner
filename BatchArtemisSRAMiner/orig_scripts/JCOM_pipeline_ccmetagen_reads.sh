#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

while getopts "p:f:q:r:" 'OPTKEY'; do
    case "$OPTKEY" in
        'p')
            # Assign project name
            project="$OPTARG"
            ;;
        'f')
            # Assign file containing file names/accessions
            file_of_accessions="$OPTARG"
            ;;
        'q')
            # Assign queue type
            queue="$OPTARG"
            ;;
        'r')
            # Assign root project name
            root_project="$OPTARG"
            ;;    
        '?')
            echo "INVALID OPTION -- ${OPTARG}" >&2
            exit 1
            ;;
        ':')
            echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
            exit 1
            ;;
    esac
done
shift $(( OPTIND - 1 ))

# Check if project name is provided
if [ -z "$project" ]
    then
        echo "No project string entered. Use -p cyanobacteria_virome"
        exit 1
fi

# Check if root project name is provided
if [ -z "$root_project" ]
    then
        echo "No root project string entered. Use -r VELAB or -r $root_project"
        exit 1
fi

# Check if file containing file names/accessions is provided
if [ -z "$file_of_accessions" ]
    then
        echo "No file containing files to run specified. Running all files in /project/$root_project/$project/contigs/final_contigs/"
        ls -d /project/"$root_project"/"$project"/contigs/final_contigs/*.fa > /project/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_ccmetagen
        export file_of_accessions="/project/$root_project/$project/contigs/final_contigs/file_of_accessions_for_ccmetagen"
    else    
        export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

# Determine the job time and queue project based on the queue type
case "$queue" in
    "defaultQ" | "alloc-eh")
        job_time="walltime=84:00:00"
        queue_project="$root_project"
        ;;
    "scavenger")
        job_time="walltime=48:00:00"
        queue_project="$root_project"
        ;;
    *)
        echo "Invalid queue type. Please specify either 'defaultQ', 'scavenger', or 'alloc-eh'"
        exit 1
        ;;
esac

# Determine the number of jobs needed from the length of input and format the J phrase for the pbs script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# If input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

qsub -J $jPhrase \
    -o "/project/$root_project/$project/logs/ccmetagen_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/ccmetagen_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_project" \
    /project/$root_project/$project/scripts/JCOM_pipeline_ccmetagen_reads.pbs
