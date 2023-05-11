#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# given a file of SRA accessions (runs), this script will download the SRA files
# it will cycle through several download methods until it finds one that works
# it will check to see if the library is paired or single and if it has downloaded correctly

# once the script is completed I would recommend using check_sra_downloads.sh to do a final check that everything has downloaded correctly
# this will output a file of accessions that have not downloaded correctly

# provide a file containing SRA accessions - make sure it is full path to file -f 

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
            echo "No project string entered. Use -p cichlid_virome"
    exit 1
    fi

    if [ "$root_project" = "" ]
        then
            echo "No root project string entered. Use -r VELAB or -r jcomvirome"
    exit 1
    fi

    if [ "$file_of_accessions" = "" ]
        then
            echo "No file containing SRA to run specified"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
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

#lets work out how many jobs we need from the length of input and format the J phrase for the pbs script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

qsub -J $jPhrase \
    -o "/project/$root_project/$project/logs/sra_download_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/sra_download_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
    -q "$queue" \
    -l "$job_time" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_download_sra.pbs