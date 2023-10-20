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
    echo "Usage: $0 [-i sequences] [-h]"
    echo "  -i sequences: Fasta file containing sequences to trim and align using TrimAl and MAFFT (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "  Example:"
    echo "  $0 -i /project/$root_project/$project/mysequences.fasta"
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "i:q:r:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'i')
        #
        sequences="$OPTARG"
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

if [ "$sequences" = "" ]; then
    echo "ERROR: No sequences provided to align use -i myseqs.fasta"
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

qsub -o "/project/$root_project/$project/logs/mafft_alignment_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/mafft_alignment_$(date '+%Y%m%d')_stderr.txt" \
    -v "sequences=$sequences" \
    -q "$queue" \
    -l "walltime=12:00:00" \
    -P "$root_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_mafft_trim.pbs
