#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# shell wrapper script to run the summary table script
# write a check that takes the name of the file_of_accession and looks for combined_blastcontigs with this name
# if it does not exist as user to specify the full path the combined blastcontigs file
# something like are these the correct paths? 
# if not specify the files using the following flags

# Set the default values
queue="defaultQ"
project="JCOM_pipeline_virome"
root_project="jcomvirome"
file_of_accessions=""

show_help() {
    echo ""
    echo "Usage: $0 [-f file_of_accessions] [-d rvdb_database] [-h]"
    echo "  -f file_of_accessions: Full path to text file containing library ids one per line. (Required)"
    echo "  -d rvdb_database: DIAMOND RVDB Database used to join RVDB results to taxonomy. (Required)"
    echo "  -t nt_results: Full path to the combined blastn results file. (Optional)"
    echo "  -n nr_results: Full path to the combined blastx results file. (Optional)"
    echo "  -h: Display this help message."
    echo ""
    echo "Anaconda and the project_pipeline and r_env environements are required to run this script."
    echo "Check the _summary_table output and error logs upon completetion to ensure that the script ran correctly and that all output files were found."
    echo ""
    echo "  Example:"
    echo "  $0 -f /project/$root_project/$project/accession_lists/mylibs.txt -d /scratch/VELAB/Databases/Blast/RVDB.prot.v^VERISON^.^MONTH^-^YEAR^.dmnd"
    echo ""
    echo ""
    echo "  Example specifying nt_results and nr_results:"
    echo "  $0 -f /project/$root_project/$project/accession_lists/mylibs.txt -d /scratch/VELAB/Databases/Blast/RVDB.prot.v^VERISON^.^MONTH^-^YEAR^.dmnd" -t /project/$root_project/$project/blast_results/combined_blastn_results.txt -n /project/$root_project/$project/blast_results/combined_blastx_results.txt
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "p:q:d:r:f:n:t:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'p')
        project="$OPTARG"
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
    't')
        nt_results="$OPTARG"
        ;;  
    'n')
        nr_results="$OPTARG"
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
    echo "No accessions provided (-f), please provide a file containing accession IDs one per line."
    show_help
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

# Define 
wd="/project/$root_project/$project/"
abundance="/scratch/$root_project/$project/abundance/final_abundance"
# Check if the rvdb_accession2taxid file exists
if [ ! -f "$rvdb_accession2taxid" ]; then
    echo "ERROR: The RVDB accession2taxid file does not exist: $rvdb_accession2taxid for the RVDB database provided: $rvdb_database"
    exit 1
fi

input_check() {
    #echo ""
    #echo "-f passes an accession file which the summary_table script will parse each ID and collect the abundance, readcount, and blast (RdRp/RVDB) results for each ID."
    #echo ""
    #echo "The summary_table script also requires the combined blast output file (i.e. _blastnr and _blastnt). It assumes this is named after the file_of_accessions provided."

    echo ""
    echo "Checking if the required files exist and are non-empty."
    echo ""
    
    # Check if -n and -t flags are provided
    if [ -n "$nr_results" ]; then
        if [ ! -s "$nr_results" ]; then
            echo "ERROR: The provided nr_results file is either missing or empty: $nr_results"
            show_help
        else
            nr_blastcontigs=$(echo "$nr_results" | sed 's/blastx_results.txt/blastcontigs.fasta/')
        fi

    fi

    if [ -n "$nt_results" ]; then
        if [ ! -s "$nt_results" ]; then
            echo "ERROR: The provided nt_results file is either missing or empty: $nt_results"
            show_help
        else
            nt_blastcontigs=$(echo "$nt_results" | sed 's/blastn_results.txt/blastcontigs.fasta/')
        fi
    fi

    # Check if -n and -t flags are not provided
    if [ -z "$nr_results" ] && [ -z "$nt_results" ]; then
        # Define the file paths
        file_of_accessions_without_path=$(basename "$file_of_accessions")
        file_of_accessions_name=$(echo "${file_of_accessions_without_path%.*}")
        nr_results="$wd/blast_results/${file_of_accessions_name}_nr_blastx_results.txt"
        nt_results="$wd/blast_results/${file_of_accessions_name}_nt_blastn_results.txt"
        nr_blastcontigs="$wd/blast_results/${file_of_accessions_name}_nr_blastcontigs.fasta"
        nt_blastcontigs="$wd/blast_results/${file_of_accessions_name}_nt_blastcontigs.fasta"
        # Check if the specified files are non-empty
        empty_files=()

        if [ ! -s "$nr_results" ]; then
            empty_files+=("$nr_results")
        fi
        if [ ! -s "$nt_results" ]; then
            empty_files+=("$nt_results")
        fi
        if [ ! -s "$nr_blastcontigs" ]; then
            empty_files+=("$nr_blastcontigs")
        fi
        if [ ! -s "$nt_blastcontigs" ]; then
            empty_files+=("$nt_blastcontigs")
        fi

        # If one or more files are empty or missing
        if [ ${#empty_files[@]} -gt 0 ]; then
            echo "The following files are empty or missing:"
            for file in "${empty_files[@]}"; do
                echo "$file"
            done
            echo "Summary table looks for blastnr and blastnt results named after the accession_file (-f). If this is not the case please specify the correct nt and nr results using -t and -n flags, respectively."
            show_help
        else
            # Prompt the user for confirmation
            echo "All of the following files are present and non-empty:"
            echo "nr_blastx_results: $nr_results"
            echo "nt_blastn_results: $nt_results"
            echo "nr_blastcontigs: $nr_blastcontigs"
            echo "nt_blastcontigs: $nt_blastcontigs"
            read -p "Is this the nt and nr results you would like to run the summary table on? (Y/N): " -r
            if [[ ! $REPLY =~ ^[Yy] ]]; then
                echo "You can specify the correct nt and nr results using -t and -n flags, respectively."
                show_help
            fi
        fi
    fi


    if [[ -z "$file_of_accessions" ]]; then
        abundance_files=("$abundance"/*_RSEM.isoforms.results)
        rdrp_blast_files=("$wd"/blast_results/*_rdrp_blastx_results.txt)
        rvdb_blast_files=("$wd"/blast_results/*_RVDB_blastx_results.txt)
        rdrp_blastcontigs_file=("$wd"/blast_results/*_rdrp_blastcontigs.fasta)
        rvdb_blastcontigs_file=("$wd"/blast_results/*_RVDB_blastcontigs.fasta)
    else
        accession_ids=$(cat "$file_of_accessions")
        abundance_files=()
        rdrp_blast_files=()
        rvdb_blast_files=()
        rdrp_blastcontigs_file=()
        rvdb_blastcontigs_file=()
        missing_files=()

        # Iterate over each accession ID and find corresponding files
        for id in $accession_ids; do
            abundance_file="$abundance"/"${id}""_RSEM.isoforms.results"
            rdrp_blast_file="$wd"/blast_results/"${id}""_rdrp_blastx_results.txt"
            rvdb_blast_file="$wd"/blast_results/"${id}""_RVDB_blastx_results.txt"
            rdrp_blastcontigs="$wd"/blast_results/"${id}""_rdrp_blastcontigs.fasta"
            rvdb_blastcontigs="$wd"/blast_results/"${id}""_RVDB_blastcontigs.fasta"

            # Check if the abundance file exists and is non-empty
            if [[ -s "$abundance_file" ]]; then
                abundance_files+=("$abundance_file")
            else
                missing_files+=("Abundance file missing or empty for accession ID: $id")
            fi

            # Check if the RdRp blast file exists and is non-empty
            if [[ -s "$rdrp_blast_file" ]]; then
                rdrp_blast_files+=("$rdrp_blast_file")
            else
                missing_files+=("RdRp blast file missing or empty for accession ID: $id")
            fi

            # Check if the RVDB blast file exists and is non-empty
            if [[ -s "$rvdb_blast_file" ]]; then
                rvdb_blast_files+=("$rvdb_blast_file")
            else
                missing_files+=("RVDB blast file missing or empty for accession ID: $id")
            fi

            # Check if the RdRp blastcontigs file exists and is non-empty
            if [[ -s "$rdrp_blastcontigs" ]]; then
                rdrp_blastcontigs_file+=("$rdrp_blastcontigs")
            else
                missing_files+=("RdRp blastcontigs file missing or empty for accession ID: $id")
            fi

            # Check if the RVDB blastcontigs file exists and is non-empty
            if [[ -s "$rvdb_blastcontigs" ]]; then
                rvdb_blastcontigs_file+=("$rvdb_blastcontigs")
            else
                missing_files+=("RVDB blastcontigs file missing or empty for accession ID: $id")
            fi
        done

        # Check if there are missing files
        if [ ${#missing_files[@]} -gt 0 ]; then
            echo "The following files are missing or empty:"
            for file in "${missing_files[@]}"; do
                echo "$file"
            done

            read -p "Do you want to continue without these files? (Y/N): " -r
            if [[ $REPLY =~ ^[Nn] ]]; then
                echo "Exiting the script."
                exit 1
            fi
        fi
    fi

    echo "Number of Abundance files loaded: ${#abundance_files[@]}" # Count the number of abundance files
    echo "Number of RdRp Blast files loaded: ${#rdrp_blast_files[@]}" # Count the number of RdRp blast files
    echo "Number of RVDB Blast files loaded: ${#rvdb_blast_files[@]}" # Count the number of RVDB blast files

    [ -s "$wd/read_count/${project}_accessions_reads" ] || {
        echo "Read count file not found or empty, please run ${project}_readcount.sh Exiting."
        exit 1
    }
}

input_check

qsub -o "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stout.txt" \
    -e "/project/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stderr.txt" \
    -v "project=$project,root_project=$root_project,file_of_accessions=$file_of_accessions,rvdb_accession2taxid=$rvdb_accession2taxid,nr_results=$nr_results,nt_results=$nt_results,nr_blastcontigs=$nr_blastcontigs,nt_blastcontigs=$nt_blastcontigs" \
    -q "$queue" \
    -l "walltime=3:00:00" \
    -P "$root_project" \
    /project/"$root_project"/"$project"/scripts/JCOM_pipeline_summary_table.pbs
