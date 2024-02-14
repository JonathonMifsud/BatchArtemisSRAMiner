#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
###############################################################################################################

# Many thanks to Sabrina Sadiq for providing the intial code that this script is based on!


# Initialize variables with default values
path_to_files=""
agrf_string=""

# Function to display usage information
usage() {
    echo "Script to rename paired AGRF fastq files to match the SRA naming convention used by the rest of the pipeline."
    echo "Usage: $0 -p <path_to_files> -a <agrf_string>"
    echo "  -p: Path to the directory containing files to rename"
    echo "  -a: AGRF flowcell id string to remove from filenames (e.g. HLG3YDSX3)"
    exit 1
}

# Parse command line options
while getopts "p:a:h" opt; do
    case "$opt" in
    p)
        path_to_files="$OPTARG"
        ;;
    a)
        agrf_string="$OPTARG"
        ;;
    h)
        usage
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        usage
        ;;
    esac
done

# Check if required arguments are provided
if [ -z "$path_to_files" ] || [ -z "$agrf_string" ]; then
    echo "Both -p and -a options are required."
    usage
fi

# Check if the path_to_files directory exists and is readable
if [ ! -d "$path_to_files" ] || [ ! -r "$path_to_files" ]; then
    echo "Error: The specified directory is not valid or not readable."
    exit 1
fi

# Iterate over the files in the specified directory
for file in "$path_to_files"/*R*.fastq.gz; do
    if [ -f "$file" ]; then
        # Extract the filename without the path
        filename=$(basename "$file")

        # Replace _R1.fastq.gz with _1.fastq.gz
        renamed="${filename/_R1.fastq.gz/_1.fastq.gz}"

        # Replace _R2.fastq.gz with _2.fastq.gz
        renamed="${renamed/_R2.fastq.gz/_2.fastq.gz}"

        # Remove agrf_string from the name
        renamed=$(sed -r "s/(${agrf_string}_\w{10}-\w{10})//" <<< "$renamed")
        renamed=$(sed 's/_/#/g' <<< "$renamed")             # change all _ to #
        renamed=$(sed 's/\(.*\)#/\1_/' <<< "$renamed")       # replace last # with _
        renamed=$(sed 's/#//g' <<< "$renamed")              # change all # to nothing

        # Construct the new filename
        new_filename="$path_to_files/$renamed"

        # Prompt the user for confirmation
        echo "Original: $file"
        echo "Renamed:  $new_filename"
        read -p "Do you want to proceed with this rename? (y/n): " choice
        if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
            # Rename the file
            mv "$file" "$new_filename"
            if [ $? -eq 0 ]; then
                echo "File renamed successfully."
            else
                echo "Error: Failed to rename the file: $file"
            fi
        else
            echo "File not renamed."
        fi
    fi
done
