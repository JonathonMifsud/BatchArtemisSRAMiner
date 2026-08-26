#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2024                                                      #
###############################################################################################################

# Set the default values
queue="defaultQ"
max_jobs=1000
project="JCOM_pipeline_virome"
root_project="jcomvirome"

show_help() {
    echo ""
    echo "Usage: $0 [-f file_of_accessions] [-h]"
    echo "  -f file_of_accessions: Full path to text file containing library ids one per line. (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "  Example:"
    echo "  $0 -f /project/$root_project/$project/accession_lists/mylibs.txt"
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "p:f:q:r:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'p')
        project="$OPTARG"
        ;;
    'f')
        file_of_accessions="$OPTARG"
        ;;
    'q')
        queue="$OPTARG"
        ;;
    'r')
        root_project="$OPTARG"
        ;;
    'h')
        show_help
        ;;
    '?')
        echo "INVALID OPTION -- ${OPTARG}" >&2
        show_help
        ;;
    ':')
        echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
        show_help
        ;;
    *)
        echo "Invalid option: -$OPTARG" >&2
        show_help
        ;;  
    esac
done
shift $((OPTIND - 1))

if [ "$project" = "" ]; then
    echo "ERROR: No project string entered. Use e.g, -p logan"
    show_help
fi

if [ "$root_project" = "" ]; then
    echo "ERROR: No root project string entered. Use e.g., -r VELAB or -r camel_mining"
    show_help
fi

if [ "$file_of_accessions" = "" ]; then
    echo "ERROR: No file containing SRA to run specified"
    show_help
else
    file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

# Function to determine walltime based on number of IDs
#get_walltime() {
#    local count=$1
#    if [ "$count" -lt 50 ]; then
#        echo "02:00:00"
#    elif [ "$count" -lt 200 ]; then
#        echo "04:00:00"
#    elif [ "$count" -lt 500 ]; then
#        echo "08:00:00"
#    else
#        echo "12:00:00"
#    fi
#}

# Calculate number of lines in the file
total_ids=$(wc -l <"$file_of_accessions")

if [ "$total_ids" -le "$max_jobs" ]; then
    # Case where total IDs are less than or equal to max_jobs
    total_ids_phrase=$(( total_ids - 1 ))
    qsub -J "0-$total_ids_phrase" \
        -o "/project/$root_project/$project/logs/logan_download_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
        -e "/project/$root_project/$project/logs/logan_download_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
        -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
        -q "$queue" \
        -l "walltime=00:15:00" \
        -l select=1:ncpus=1:mem=6GB \
        -P "$root_project" \
        /project/"$root_project"/"$project"/scripts/JCOM_pipeline_download_logan.pbs
else
    num_chunks=$(( (total_ids + max_jobs - 1) / max_jobs ))

    split -l $max_jobs -d -a 4 "$file_of_accessions" "${file_of_accessions}_chunk_"
    for file in "${file_of_accessions}_chunk_"*; do
        mv "$file" "$file.txt"
    done
    
    for chunk in "${file_of_accessions}_chunk_"*.txt; do
        chunk_size=$(wc -l < "$chunk")
        jPhrase="0-$((chunk_size - 1))"
        #walltime=$(get_walltime "$chunk_size")

        qsub -J "$jPhrase" \
            -o "/project/$root_project/$project/logs/logan_download_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
            -e "/project/$root_project/$project/logs/logan_download_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
            -v "project=$project,file_of_accessions=$chunk,root_project=$root_project" \
            -q "$queue" \
            -l "walltime=00:15:00" \
            -l select=1:ncpus=1:mem=6GB \
            -P "$root_project" \
            /project/"$root_project"/"$project"/scripts/JCOM_pipeline_download_logan.pbs
    done
fi