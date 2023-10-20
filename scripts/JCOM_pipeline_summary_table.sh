#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run the summary table script

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"
file_of_accessions=""

show_help() {
    echo ""
    echo "Usage: $0 [-f file_of_accessions] [-d rvdb_database] [-h]"
    echo "  -f file_of_accessions: Full path to text file containing library ids one per line. If not provided, files in the resutls folders will be used. (Optional)"
    echo "  -d rvdb_database: DIAMOND RVDB Database used to join RVDB results to taxonomy. (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "Anaconda and the project_pipeline and r_env environements are required to run this script."
    echo "Check the _summary_table output and error logs upon completetion to ensure that the script ran correctly and that all output files were found."
    echo ""
    echo "  Example:"
    echo "  $0 -f /project/$root_project/$project/accession_lists/mylibs.txt -d /scratch/VELAB/Databases/Blast/RVDB.prot.v^VERISON^.^MONTH^-^YEAR^.dmnd"
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "p:q:d:r:f:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'p')
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
    'q')
        queue="$OPTARG"
        ;;
    'd')
        rvdb_database="$OPTARG"
        ;;
    'r')
        root_project="$OPTARG"
        ;;
    'f')
        file_of_accessions="$OPTARG"
        ;;
    'h')
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
    echo "No accessions provided (-f), Summary table will generated using all accessions in '/project/$root_project/$project/contigs/' '/project/$root_project/$project/blast_results/' etc"
else
    file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi

if [ "$rvdb_database" = "" ]; then
    echo "ERROR: No RVDB database provided (-d). Please provide the full path to the RVDB database used in blastx. Use e.g., /scratch/VELAB/Databases/Blast/RVDB.prot.v26.Jul-2023.dmnd"
    show_help
fi

# We are finding the corresponding accession2taxid file for the RVDB database
# This relys on the naming convention of the RVDB database build script /scratch/VELAB/Databases/update_db_3.pbs
rvdb_accession2taxid=$(echo "$rvdb_database" | sed 's/.dmnd/.accession2taxid.txt/g')

# Check if the rvdb_accession2taxid file exists
if [ ! -f "$rvdb_accession2taxid" ]; then
    echo "The RVDB accession2taxid file does not exist: $rvdb_accession2taxid for the RVDB database provided: $rvdb_database"
    exit 1
fi

qsub -o "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,root_project=$root_project,file_of_accessions=$file_of_accessions,rvdb_accession2taxid=$rvdb_accession2taxid" \
    -q "$queue" \
    -l "walltime=3:00:00" \
    -P "$root_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_summary_table.pbs
