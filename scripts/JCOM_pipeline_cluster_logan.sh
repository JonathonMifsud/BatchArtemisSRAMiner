#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2024                                                      #
###############################################################################################################

# Set the default values
queue="defaultQ"
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

if [ -z "$project" ]; then
    echo "ERROR: No project string entered. Use e.g., -p logan"
    show_help
fi

if [ -z "$root_project" ]; then
    echo "ERROR: No root project string entered. Use e.g., -r VELAB or -r camel_mining"
    show_help
fi

if [ -z "$file_of_accessions" ]; then
    echo "ERROR: No file containing SRA to run specified."
    show_help
else
    if [ ! -f "$file_of_accessions" ]; then
        echo "ERROR: The specified accession file does not exist."
        exit 1
    fi
    file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

qsub -o "/project/$root_project/$project/logs/logan_cluster_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/logan_cluster_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
    -q "$queue" \
    -l "walltime=24:00:00" \
    -l select=1:ncpus=12:mem=120GB \
    -P "$root_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_cluster_logan.pbs
