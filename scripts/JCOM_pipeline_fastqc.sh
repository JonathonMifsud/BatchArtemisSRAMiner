#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run fastqc for project folder

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"

while getopts "p:f:r:" 'OPTKEY'; do
    case "$OPTKEY" in
    'p')
        #
        project="$OPTARG"
        ;;
    'f')
        #
        file_of_accessions="$OPTARG"
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
    *)
        # Handle invalid flags here
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;  
    esac
done
shift $((OPTIND - 1))

if [ "$project" = "" ]; then
    echo "No project string entered. Use e.g, -p JCOM_pipeline_virome"
    exit 1
fi

if [ "$root_project" = "" ]; then
    echo "No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    exit 1
fi

if [ "$file_of_accessions" = "" ]; then
    echo "No file containing files to run specified running all files in /scratch/$root_project/$project/raw_reads/ and /scratch/$root_project/$project/trimmed_files/"
    ls -d /scratch/"$root_project"/"$project"/raw_reads/*.fastq.gz >/scratch/"$root_project"/"$project"/raw_reads/file_of_accessions
    ls -d /scratch/"$root_project"/"$project"/trimmed_reads/*.fastq.gz >>/scratch/"$root_project"/"$project"/raw_reads/file_of_accessions
    export file_of_accessions="/scratch/$root_project/$project/raw_reads/file_of_accessions"
else
    export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

#lets work out how many jobs we need from the length of input and format the J phrase for the pbs script
jMax=$(wc -l <"$file_of_accessions")
jIndex=$(expr "$jMax" - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

qsub -v "project=$project,file_of_accessions=$file_of_accessions" \
    -J "$jPhrase" \
    -q "$queue" \
    -o "/project/$root_project/$project/logs/fastqc_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/fastqc_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
    /project/$root_project/$project/scripts/JCOM_pipeline_fastqc.pbs