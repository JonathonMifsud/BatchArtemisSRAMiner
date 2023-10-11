#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run iqtree
# provide an alignment
model="MFP"

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"

while getopts "i:q:m:r:p:" 'OPTKEY'; do
    case "$OPTKEY" in
    'i')
        #
        alignment="$OPTARG"
        ;;
    'q')
        #
        queue="$OPTARG"
        ;;
    'm')
        #
        model="$OPTARG"
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

if [ "$alignment" = "" ]; then
    echo "No alignment provided to align use -i myseqs.fasta"
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

qsub -o "/project/$root_project/$project/logs/iqtree_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/iqtree_$(date '+%Y%m%d')_stderr.txt" \
    -v "alignment=$alignment,model=$model" \
    -q "$queue" \
    -l "walltime=48:00:00" \
    -P "$root_project" \
    /project/$root_project/$project/scripts/JCOM_pipeline_iqtree.pbs
