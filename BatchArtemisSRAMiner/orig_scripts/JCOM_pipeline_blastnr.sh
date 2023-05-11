#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# This script will run blastx on .contigs.fa files from the final_contigs folder
# It will then extract the contigs that have a blast hit to the nr database

# I tend to run this once per project on a single file containing all the contigs concatenated together resulting from the Rdrp and RVDB blasts (i.e. the blastcontig.fa files in blast_results/)

# You will need to provide the following arguments:

# Set the default queue
queue="defaultQ"

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
            'd')
                #
                db="$OPTARG"
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
            echo "No project string entered. Use -p 1_dogvirome or -p 2_sealvirome or cichlid_virome"
    exit 1
    fi

    if [ "$root_project" = "" ]
        then
            echo "No root project string entered. Use -r VELAB or -r jcomvirome"
    exit 1
    fi

    if [ "$db" = "" ]
        then
            echo "No database specified. Use -d option to specify the database."
            exit 1
    fi
    
    if [ "$file_of_accessions" = "" ]
        then
            # if no file of accessions is provided then run all files in the final_contigs directory
            echo "No file containing files to run specified running all files in /project/$root_project/$project/contigs/final_contigs/"
            ls -d /project/"$root_project"/"$project"/contigs/final_contigs/*.fa > /project/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_blastxNR
            export file_of_accessions="/project/$root_project/$project/contigs/final_contigs/file_of_accessions_for_blastxNR"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

    # NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
    if [ "$queue" = "defaultQ" ]
        then 
            job_time="walltime=48:00:00"
            queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
            cpu="ncpus=12"
            mem="mem=120GB"
            diamond_cpu="12"
            diamond_mem="4"
            diamond_para="-e 1E-4 -c1 -b $diamond_mem -p $diamond_cpu --more-sensitive -k10 --tmpdir /scratch/$root_project/"
    fi

    if [ "$queue" = "scavenger" ]
        then 
            job_time="walltime=48:00:00"
            queue_project="$root_project"
            cpu="ncpus=12"
            mem="mem=120GB"
            diamond_cpu="12"
            diamond_mem="4"
            diamond_para="-e 1E-4 -c2 -b $diamond_mem -p $diamond_cpu --more-sensitive -k10 --tmpdir /scratch/$root_project/"
    fi

    if [ "$queue" = "alloc-eh" ]
        then 
            job_time="walltime=200:00:00"
            queue_project="VELAB"
            cpu="ncpus=24"
            mem="mem=120GB"
            diamond_cpu="24"
            diamond_mem="4"
            diamond_para="-e 1E-5 -c1 -b $diamond_mem -p $diamond_cpu --more-sensitive -k10 --tmpdir /scratch/$root_project/"
    fi

    if [ "$queue" = "intensive" ]
        then 
            job_time="walltime=124:00:00"
            queue_project="VELAB"
            queue="defaultQ"
            cpu="ncpus=24"
            mem="mem=220GB"
            diamond_cpu="24"
            diamond_mem="8"
            diamond_para="-e 1E-4 -c1 -b $diamond_mem -p $diamond_cpu --more-sensitive -k5 --tmpdir /scratch/$root_project/"
    fi


    if [ "$queue" = "intensive_alloc-eh" ]
        then 
            job_time="walltime=180:00:00"
            queue_project="VELAB"
            queue="alloc-eh"
            cpu="ncpus=24"
            mem="mem=220GB"
            diamond_cpu="24"
            diamond_mem="8"
            diamond_para="-e 1E-4 -c1 -b $diamond_mem -p $diamond_cpu --more-sensitive -k5 --tmpdir /scratch/$root_project/"
    fi

#lets work out how many jobs we need from the length of input and format the J phrase for the pbs script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

# Run the blastx jobs
qsub -J $jPhrase \
    -o "/project/$root_project/$project/logs/blastnr_^array_index^_$project_$queue_$db_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/blastnr_^array_index^_$project_$queue_$db_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,diamond_para=$diamond_para,db=$db" \
    -q "$queue" \
    -l "$job_time" \
    -l "$cpu" \
    -l "$mem" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_blastnr.pbs