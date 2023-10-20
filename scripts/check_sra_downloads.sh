#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
###############################################################################################################

# A function to check if the dir contains all of the sras specified in the file_of_accessions
# This is useful for checking if the download was successful
# It also looks to see if both paired end files are present for each SRA
# And removes the pesky third file that is not useful - atleast with my understanding of it

# Set the default values
project="JCOM_pipeline_virome"
root_project="jcomvirome"

show_help() {
    echo "Usage: $0 [-f file_of_accessions] [-d directory] [-h]"
    echo "  -f file_of_accessions: Full path to text file containing library ids (i.e., SRA run ids), one per line (Required)"
    echo "  -d directory: Directory containing the raw sequence files (Required)"
    echo "  -h: Display this help message."
    echo ""
    echo "  Example:"
    echo "  $0 -f /project/$root_project/$project/accession_lists/mylibs.txt -d /scratch/$root_project/$project/raw_reads"
    echo ""
    echo " Check the Github page for more information:"
    echo " https://github.com/JonathonMifsud/BatchArtemisSRAMiner "
    exit 1
}

while getopts "d:f:h" 'OPTKEY'; do
    case "$OPTKEY" in
    'd')
        # dir containing the raw sequence files
        directory="$OPTARG"
        ;;
    'f')
        # text file containing the SRA accessions that should be downloaded used to cross reference files in the directory
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

if [ "$directory" = "" ]; then
    echo "ERROR: No directory string entered. Use -d to specify the FULL PATH to the directory containing raw sequence files"
    echo ""
    show_help
fi

if [ "$file_of_accessions" = "" ]; then
    echo "ERROR: No file containing SRA to run specified. Use -f file containing SRA accessions"
    echo ""
    show_help
fi

# Get a list of all of the SRA ids in the current directory
ls "$directory"/*.fastq.gz | perl -ne '$_ =~ s[.*/(.*)][$1]; print "$_";' | cut -d'_' -f1 | cut -d'.' -f1 | sort | uniq >"$directory"/sra_ids.txt

# if missing_sra_ids.txt exists already, remove it
if [ -f "$directory"/missing_sra_ids.txt ]; then
    rm "$directory"/missing_sra_ids.txt
fi

# For each SRA id, check if the fastq files exist
for i in $(cat "$directory"/sra_ids.txt); do
    if [ -f "$directory"/"$i"".fastq.gz" ] && [ ! -f "$directory"/"$i""_1.fastq.gz" ]; then #e.g. if SRR1249328.fastq.gz exists and SRR1249328_1.fastq.gz doesn't layout == single
        export layout="single"
    fi

    if [ ! -f "$directory"/"$i"".fastq.gz" ] && [ -f "$directory"/"$i""_1.fastq.gz" ]; then #e.g. if SRR1249328.fastq.gz does not exist and SRR1249328_1.fastq.gz does layout == paired
        export layout="paired"
    fi

    if [ -f "$directory"/"$i"".fastq.gz" ] && [ -f "$directory"/"$i""_1.fastq.gz" ]; then #e.g. in the case both single and paired read files exist try to assemble using paired files, layout == paired
        export layout="triple"
    fi

    # If layout is triple, remove the single file, and set layout to paired
    # From what I understand the third file is techinal reads and not biological and these are not useful
    if [ "$layout" = "triple" ]; then
        rm "$directory"/"$i"".fastq.gz"
        export layout="paired"
    fi

    # If layout is paired, check if the second file exists
    if [ "$layout" = "paired" ]; then
        if [ ! -f "$directory"/"$i""_2.fastq.gz" ]; then
            # If it does not exist, remove the first file
            rm "$directory"/"$i""_1.fastq.gz"
            # And add the SRA id to a file containing the missing SRA ids
            echo "$i" >>"$directory"/missing_sra_ids.txt
        fi
    fi

    # If layout is single, check if the file exists
    # This should be redundant as the sra list is based on the inital ls but I am leaving it in for now
    if [ "$layout" = "single" ]; then
        if [ ! -f "$directory"/"$i"".fastq.gz" ]; then
            # If it does not exist, add the SRA id to a file containing the missing SRA ids
            echo "$i" >>"$directory"/missing_sra_ids.txt
        fi
    fi
done

# Get a list of all of the SRA ids in the current directory after the cleanup
ls "$directory"/*.fastq.gz | perl -ne '$_ =~ s[.*/(.*)][$1]; print "$_";' | cut -d'_' -f1 | cut -d'.' -f1 | sort | uniq >"$directory"/cleanup_sra_ids.txt

# Compare the cleanup list to the original list
# If they do not match, add the missing SRA ids to the missing_sra_ids.txt file
grep -Fxvf "$directory"/cleanup_sra_ids.txt "$file_of_accessions" >>"$directory"/missing_sra_ids.txt

# It is likely that there will be duplicates in the missing_sra_ids.txt file
# Remove the duplicates and edit the file in place
awk '!a[$0]++' "$directory"/missing_sra_ids.txt >"$directory"/missing_sra_ids.txt.tmp && mv "$directory"/missing_sra_ids.txt.tmp "$directory"/missing_sra_ids.txt

# Reset the color without outputting anything
reset_color="\e[0m"

# If the number of lines in the missing_sra_ids.txt file is 0, then all of the SRA ids were downloaded
# If it is not 0, then some of the SRA ids were not downloaded
# Check the number of lines in the file
# If the number of lines in the missing_sra_ids.txt file (ignoring empty lines) is 0, then all of the SRA ids were downloaded
# If it is not 0, then some of the SRA ids were not downloaded
# Check the number of lines in the file
if [ $(grep -c . "$directory"/missing_sra_ids.txt) -eq 0 ]; then
    str="It's a Christmas miracle, all of the SRA ids were downloaded!"
    color1="\e[31m" # Red
    color2="\e[32m" # Green
    new_str=""
    for ((i = 0; i < ${#str}; i++)); do
        if ((i % 2 == 0)); then
            new_str+="${color1}${str:$i:1}"
        else
            new_str+="${color2}${str:$i:1}"
        fi
    done
    new_str+="\e[39m" # Reset color
    echo -e $new_str
else
    # Output the number of missing SRA ids
    # Change colour to red because we are fancy
    echo -e "\e[31m""Some of the SRA ids were not downloaded or partially downloaded\n"
    echo -e "\e[31m""Number of missing SRA ids:"
    grep . "$directory"/missing_sra_ids.txt | wc -l
    echo -e "\e[31m""\nThey are the following:\n"
    grep . "$directory"/missing_sra_ids.txt
    echo -e "\nmissing_sra_ids.txt has been created in the -d directory and contains the missing SRA ids\n"
    echo -e "\nTry redownloading them using the missing_sra_ids.txt file as the -f input"
    echo -e "${reset_color}"

    # Check for temp_SRR..._file and generate a warning if found.
    temp_files=()
    for file in "$directory"/*; do
        if [[ $file =~ temp_SRR.*_file ]]; then
            # Remove path and unwanted parts from the filename
            temp_file=${file##*/}        # Remove path
            temp_file=${temp_file#temp_} # Remove 'temp_' prefix
            temp_file=${temp_file%_file} # Remove '_file' suffix
            temp_files+=("$temp_file")
        fi
    done

    if [ ${#temp_files[@]} -ne 0 ]; then
        echo -e "\e[33m""Warning: Temporary files detected. These might be a symptom of failed downloads for the related SRA ids. We advise you to verify that both read files are non-empty and of comparable size for the following ids:"
        for temp_file in "${temp_files[@]}"; do
            echo "$temp_file"
        done

        echo -e "\e[33m""If files are parital, remove them and rerun this script to get an updated missing_sra_ids.txt file which can be used as input for redownloading."
        echo -e "${reset_color}"
    fi
fi

# Clean up
rm "$directory"/sra_ids.txt
rm "$directory"/cleanup_sra_ids.txt
