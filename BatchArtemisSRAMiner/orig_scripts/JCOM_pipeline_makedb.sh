#!/bin/bash

# shell wrapper script to run the summary table script

while getopts "i:" 'OPTKEY'; do
    case "$OPTKEY" in
            'i')
                #
                input="$OPTARG"
                ;;    
        esac
    done
    shift $(( OPTIND - 1 ))

    if [ "$input" = "" ]
        then
            echo "No input provided"
    exit 1
    fi

qsub -o "/project/$root_project/$project/logs/makedb_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/makedb_$(date '+%Y%m%d')_stderr.txt" \
    -v "input=$input" \
    -P "jcomvirome" \
   /project/"$root_project"/"$project"/scripts/JCOM_pipeline_makedb.pbs