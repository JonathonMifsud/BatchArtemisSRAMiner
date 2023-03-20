#!/bin/bash

# shell wrapper script to run blastx against the RdRp database
# provide a file containing the names of the read files to run only one per library! example only the first of the pairs
# if you do not provide it will use thoes in $project trimmed_reads

while getopts "p:f:q:r:" 'OPTKEY'; do
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

    if [ "$project" = "" ]
        then
            echo "No project string entered. Use -p 1_dogvirome or -p 2_sealvirome"
    exit 1
    fi

    if [ "$file_of_accessions" = "" ]
        then
            echo "No file containing files to run specified running all files in /project/$root_project/$project/contigs/final_contigs/"
            ls -d /project/"$root_project"/"$project"/contigs/final_contigs/*.fa > /project/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_blastx_rdrp
            export file_of_accessions="/project/$root_project/$project/contigs/final_contigs/file_of_accessions_for_blastx_rdrp"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

     # NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
    if [ "$queue" = "defaultQ" ]
        then 
            job_time="walltime=24:00:00"
            queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
    fi

      if [ "$queue" = "scavenger" ]
        then 
            job_time="walltime=48:00:00"
            queue_project="$root_project"
    fi

          if [ "$queue" = "alloc-eh" ]
        then 
            job_time="walltime=84:00:00"
            queue_project="VELAB"
    fi

#lets work out how many jobs we need from the length of input and format the J phrase for the pbs script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

qsub -J $jPhrase \
    -o "/project/$root_project/$project/logs/blastxRdRp_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/blastxRdRp_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_projec" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_blastxRdRp.pbs
    