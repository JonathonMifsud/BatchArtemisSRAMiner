#!/bin/bash

# shell wrapper script to run blastx against the RdRp database
# provide a file containing the names of the read files to run only one per library! example only the first of the pairs
# if you do not provide it will use thoes in $project trimmed_reads
# Get the current working directory
wd=$(pwd)

while getopts "i:d:" 'OPTKEY'; do
    case "$OPTKEY" in
            'i')
                # 
                input="$OPTARG"
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
        esac
    done
    shift $(( OPTIND - 1 ))

    if [ "$input" = "" ]
         then
            echo "No input string provided."
    exit 1
    fi


    if [ "$db" = "" ]
        then
            echo "No database specified. Use -d option to specify the database."
            exit 1
    fi

input_basename=$(basename "$input")

qsub -o "/project/$root_project/$project/logs/blastx_$input_basename_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/blastx_$input_basename_$(date '+%Y%m%d')_stderr.txt" \
    -v "input=$input,db=$db,wd=$wd" \
    -q "$defaultQ" \
    -l "$job_time" \
    -P "jcomvirome" \
     /project/$root_project/$project/scripts/JCOM_pipeline_blastx_custom.pbs
    

