#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run fasttree
# provide an alignment

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"

show_help() {
    echo ""
    echo "Usage: $0 [-i alignment] [-h]"
    echo "  -i alignment: sequence alignment to build tree from, provide the full path. (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "  Example:"
    echo "  $0 -i /project/$root_project/$project/virus_alignment.fasta"
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "i:q:r:p:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'i')
        #
        alignment="$OPTARG"
        ;;
    'q')
        #
        queue="$OPTARG"
        ;;
    'r')
        #
        root_project="$OPTARG"
        ;;
    'p')
        #
        project="$OPTARG"
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

if [ "$alignment" = "" ]; then
    echo "ERROR: No alignment provided to align use -i myseqs.fasta"
    show_help
fi

if [ "$project" = "" ]; then
    echo "ERROR: No project string entered. Use e.g, -p JCOM_pipeline_virome"
    show_help
fi

if [ "$root_project" = "" ]; then
    echo "ERROR: No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    show_help
fi

qsub -o "/project/"$root_project"/"$project"/logs/fasttree_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/"$root_project"/"$project"/fasttree_$(date '+%Y%m%d')_stderr.txt" \
    -v "alignment=$alignment" \
    -q "$queue" \
    -l "walltime=48:00:00" \
    -P "$root_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_fasttree.pbs
