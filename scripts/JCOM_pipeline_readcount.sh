#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
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
    'h')
        #
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
        # Handle invalid flags here
        echo "Invalid option: -$OPTARG" >&2
        show_help
        ;;
    esac
done
shift $((OPTIND - 1))
if [ "$project" = "" ]; then
    echo "ERROR: No project string entered. Use e.g, -p JCOM_pipeline_virome"
    show_help
fi

if [ "$root_project" = "" ]; then
    echo "ERROR: No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    show_help
fi

if [ "$file_of_accessions" = "" ]; then
    echo "ERROR: No accession file containing library ids to run please specify this with -f"
    show_help
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

qsub -J "$jPhrase" \
    -o "/project/$root_project/$project/logs/readcount_^array_index^_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/readcount_^array_index^_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
    -q "$queue" \
    -l "walltime=8:00:00" \
    -P "$root_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_readcount.pbs
