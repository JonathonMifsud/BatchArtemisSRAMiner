#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# This script will run blastn on .contigs.fa files from the final_contigs folder
# It will then extract the contigs that have a blast hit to the nr database

# I tend to run this once per project on a single file containing all the contigs concatenated together resulting from the Rdrp and RVDB blasts (i.e. the blastcontig.fa files in blast_results/)

# provide a file containing SRA accessions - make sure it is full path to file -f 

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

    if [ "$db" = "" ]
        then
            echo "No database specified. Use e.g., -d /scratch/VELAB/Databases/Blast/nt.Jul-2023/nt"
    exit 1
    fi
    
    if [ "$file_of_accessions" = "" ]
        then
            echo "No file containing files to run specified running all files in /project/$root_project/$project/contigs/final_contigs/"
            ls -d /project/"$root_project"/"$project"/contigs/final_contigs/*.fa > /project/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_blastNT
            export file_of_accessions="/project/$root_project/$project/contigs/final_contigs/file_of_accessions_for_blastNT"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

    if [ "$queue" = "defaultQ" ]; then
        echo "Queue set to defaultQ"
    fi

    # NR sometime goes over 48 hours we cant increase this in scavenger queue but if queue is set to defaultQ we can
    if [ "$queue" = "defaultQ" ]
        then 
            job_time="walltime=120:00:00"
            queue_project="$root_project" # what account to use in the pbs script this might be differnt from the root dir
            cpu="ncpus=24"
            mem="mem=220GB"
            blast_cpu="24"
            blast_para="-max_target_seqs 10 -num_threads $cpu -mt_mode 1 -evalue 1E-10 -subject_besthit -outfmt '6 qseqid qlen sacc salltitles staxids pident length evalue'"
    fi

    if [ "$queue" = "intensive" ]
        then 
            job_time="walltime=124:00:00"
            queue_project="VELAB"
            queue="defaultQ"
            cpu="ncpus=24"
            mem="mem=220GB"
            blast_cpu="24"
            blast_mem="8"
            blast_para="-max_target_seqs 10 -num_threads $cpu -mt_mode 1 -evalue 1E-10 -subject_besthit -outfmt '6 qseqid qlen sacc salltitles staxids pident length evalue'"
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
    -o "/project/$root_project/$project/logs/blastnt_^array_index^_$project_$queue_$db_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/blastnt_^array_index^_$project_$queue_$db_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,blast_para=$blast_para,cpu=$cpu,db=$db" \
    -q "$queue" \
    -l "$job_time" \
    -l "$cpu" \
    -l "$mem" \
    -P "$queue_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_blastnt.pbs