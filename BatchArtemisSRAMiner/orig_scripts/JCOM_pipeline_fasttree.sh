#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# shell wrapper script to run fasttree
# provide an alignment

while getopts "i:q:" 'OPTKEY'; do
    case "$OPTKEY" in
            'i')
                # 
                alignment="$OPTARG"
                ;;
            'q')
                # 
                queue="$OPTARG"
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

    if [ "$alignment" = "" ]
        then
            echo "No alignment provided to align use -i myseqs.fasta" 
    exit 1
    fi

     # NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
    if [ "$queue" = "defaultQ" ]
        then 
            job_time="walltime=84:00:00"
            queue_project="jcomvirome" # what account to use in the pbs script this might be differnt from the root dir
    fi

      if [ "$queue" = "scavenger" ]
        then 
            job_time="walltime=48:00:00"
            queue_project="jcomvirome"
    fi

          if [ "$queue" = "alloc-eh" ]
        then 
            job_time="walltime=84:00:00"
            queue_project="VELAB"
    fi


qsub -o "/project/"$root_project"/"$project"/logs/fasttree_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/"$root_project"/"$project"/fasttree_$(date '+%Y%m%d')_stderr.txt" \
    -v "alignment=$alignment" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_fasttree.pbs