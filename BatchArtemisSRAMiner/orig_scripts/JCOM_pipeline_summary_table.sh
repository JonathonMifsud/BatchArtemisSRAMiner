#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# shell wrapper script to run the summary table script

while getopts "p:q:r:" 'OPTKEY'; do
    case "$OPTKEY" in
            'p')
                # 
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
                # 
                queue="$OPTARG"
                ;;
            'r')
                #
                root_project="$OPTARG"
                ;;    
        esac
    done
    shift $(( OPTIND - 1 ))

    if [ "$project" = "" ]
        then
            echo "No project string entered. Use -p and the name of your project"
    exit 1
    fi

    if [ "$root_project" = "" ]
        then
            echo "No root project string entered. Use -r VELAB or -r your root project name."
    exit 1
    fi

         # NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
    if [ "$queue" = "defaultQ" ]
        then 
            job_time="walltime=12:00:00"
            queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
    fi

    if [ "$queue" = "scavenger" ]
        then 
            job_time="walltime=12:00:00"
            queue_project="$root_project"
    fi

    if [ "$queue" = "alloc-eh" ]
        then 
            job_time="walltime=12:00:00"
            queue_project="VELAB"
    fi

qsub -o "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,root_project=$root_project" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_summary_table.pbs