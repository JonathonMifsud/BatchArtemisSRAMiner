#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run blastx against the RdRp database
# provide a file containing the names of the read files to run only one per library! example only the first of the pairs
# if you do not provide it will use thoes in $project trimmed_reads

# Get the current working directory
wd=$(pwd)

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"

show_help() {
    echo "Usage: $0 [-i input] [-d db] [-h]"
    echo "  -i input: Input fasta file to blast, provide the full path. (Required)"
    echo "  -d db: Database for blastx. (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "  Example:"
    echo "  $0 -i /path/to/input/mylib.contigs.fa -d /path/to/blast/db.dmnd"
    echo ""
    exit 1
}

while getopts "i:d:p:r:h:" 'OPTKEY'; do
    case "$OPTKEY" in
    'i')
        #
        input="$OPTARG"
        ;;
    'd')
        #
        db="$OPTARG"
        ;;
    'p')
        #
        project="$OPTARG"
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
        echo ""
        show_help
        exit 1
        ;;
    ':')
        echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
        echo ""
        show_help
        exit 1
        ;;
    *)
        # Handle invalid flags here
        echo "Invalid option: -$OPTARG" >&2
        echo ""
        show_help
        exit 1
        ;;    
    esac
done
shift $((OPTIND - 1))

if [ "$input" = "" ]; then
    echo "No input string provided."
    exit 1
fi

if [ "$db" = "" ]; then
    echo "No database specified. Use -d option to specify the database."
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

input_basename=$(basename "$input")

qsub -o /project/"$root_project"/"$project"/logs/blastx_"$input_basename"_"$(date '+%Y%m%d')"_stout.txt \
    -e /project/"$root_project"/"$project"/logs/blastx_"$input_basename"_"$(date '+%Y%m%d')"_stderr.txt \
    -v "input=$input,db=$db,wd=$wd" \
    -q "$queue" \
    -l "walltime=48:00:00" \
    -P "jcomvirome" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_blastx_custom.pbs
