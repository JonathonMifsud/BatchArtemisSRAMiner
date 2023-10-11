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

while getopts "i:q:r:" 'OPTKEY'; do
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

if [ "$sequences" = "" ]; then
    echo "No sequences provided to align use -i myseqs.fasta"
    exit 1
fi

if [ "$project" = "" ]; then
    echo "No project string entered. Use e.g, -p JCOM_pipeline_virome"
    exit 1
fi

if [ "$root_project" = "" ]; then
    echo "No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    exit 1
fi

qsub -o "/project/$root_project/$project/logs/mafft_alignment_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/mafft_alignment_$(date '+%Y%m%d')_stderr.txt" \
    -v "sequences=$sequences" \
    -q "$queue" \
    -l "walltime=12:00:00" \
    -P "$root_project" \
    /project/$root_project/$project/scripts/JCOM_pipeline_mafft_trim.pbs
