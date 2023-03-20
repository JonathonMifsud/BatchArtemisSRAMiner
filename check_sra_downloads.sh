#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# A function to check if the dir contains all of the sras specified in the file_of_accessions
# This is useful for checking if the download was successful
# It also looks to see if both paired end files are present for each SRA
# And removes the pesky third file that is not useful - atleast with my understanding of it

while getopts "d:f:" 'OPTKEY'; do
    case "$OPTKEY" in
            'd')
                # dir containing the raw sequence files
                directory="$OPTARG"
                ;;
            'f')
                # text file containing the SRA accessions that should be downloaded used to cross reference files in the directory
                file_of_accessions="$OPTARG"
                ;;
            
        esac
    done
    
    shift $(( OPTIND - 1 ))

    if [ "$directory" = "" ]
        then
            echo "No directory string entered. Use -d to specify the FULL PATH to the directory containing raw sequence files"
    exit 1
    fi

    if [ "$file_of_accessions" = "" ]
        then
            echo "No file containing SRA to run specified. Use -f file containing SRA accessions"
    exit 1
    fi



# Get a list of all of the SRA ids in the current directory
ls "$directory"/*.fastq.gz | perl -ne '$_ =~ s[.*/(.*)][$1]; print "$_";' | cut -d'_' -f1  | cut -d'.' -f1 | sort | uniq > "$directory"/sra_ids.txt


# if missing_sra_ids.txt exists already, remove it
if [ -f "$directory"/missing_sra_ids.txt ]; then
    rm "$directory"/missing_sra_ids.txt
fi

# For each SRA id, check if the fastq files exist
for i in $(cat "$directory"/sra_ids.txt); do
    if [ -f "$directory"/"$library_id"".fastq.gz" ] && [ ! -f "$directory"/"$library_id""_1.fastq.gz" ]; then #e.g. if SRR1249328.fastq.gz exists and SRR1249328_1.fastq.gz doesn't layout == single
        export layout="single"
    fi

    if [ ! -f "$directory"/"$library_id"".fastq.gz" ] && [ -f "$directory"/"$library_id""_1.fastq.gz" ]; then #e.g. if SRR1249328.fastq.gz does not exist and SRR1249328_1.fastq.gz does layout == paired
        export layout="paired"
    fi

    if [ -f "$directory"/"$library_id"".fastq.gz" ] && [ -f "$directory"/"$library_id""_1.fastq.gz" ]; then #e.g. in the case both single and paired read files exist try to assemble using paired files, layout == paired
        export layout="triple"
    fi

    # If layout is triple, remove the single file, and set layout to paired
    # From what I understand the third file is techinal reads and not biological and these are not useful
    if [ "$layout" = "triple" ]; then
        rm "$directory"/"$library_id"".fastq.gz"
        export layout="paired"
    fi

    # If layout is paired, check if the second file exists
    if [ "$layout" = "paired" ]; then
        if [ ! -f "$directory"/"$library_id""_2.fastq.gz" ]; then
            # If it does not exist, remove the first file
            rm "$directory"/"$library_id""_1.fastq.gz"
            # And add the SRA id to a file containing the missing SRA ids
            echo "$library_id" >> "$directory"/missing_sra_ids.txt
        fi
    fi

    # If layout is single, check if the file exists
    # This should be redundant as the sra list is based on the inital ls but I am leaving it in for now
    if [ "$layout" = "single" ]; then
        if [ ! -f "$directory"/"$library_id"".fastq.gz" ]; then
            # If it does not exist, add the SRA id to a file containing the missing SRA ids
            echo "$library_id" >> "$directory"/missing_sra_ids.txt
        fi
    fi
done 

# Get a list of all of the SRA ids in the current directory after the cleanup
ls "$directory"/*.fastq.gz | perl -ne '$_ =~ s[.*/(.*)][$1]; print "$_";' | cut -d'_' -f1  | cut -d'.' -f1 | sort | uniq > "$directory"/cleanup_sra_ids.txt

# Compare the cleanup list to the original list
# If they do not match, add the missing SRA ids to the missing_sra_ids.txt file
grep -Fxvf "$directory"/cleanup_sra_ids.txt  "$file_of_accessions" >> "$directory"/missing_sra_ids.txt

# It is likely that there will be duplicates in the missing_sra_ids.txt file
# Remove the duplicates and edit the file in place
awk '!a[$0]++' "$directory"/missing_sra_ids.txt > "$directory"/missing_sra_ids.txt.tmp && mv "$directory"/missing_sra_ids.txt.tmp "$directory"/missing_sra_ids.txt


# If the number of lines in the missing_sra_ids.txt file is 0, then all of the SRA ids were downloaded
# If it is not 0, then some of the SRA ids were not downloaded
# Check the number of lines in the file
if [ $(wc -l < "$directory"/missing_sra_ids.txt) -eq 0 ]; then
    echo -e "\e[32m""It's a Christmas miracle, all of the SRA ids were downloaded!"
else
    # Output the number of missing SRA ids
    # Change colour to red because we are fancy
    echo -e "\e[31m""Some of the SRA ids were not downloaded or partially downloaded\n"
    echo -e "\e[31m""Number of missing SRA ids:"
    wc -l "$directory"/missing_sra_ids.txt
    echo -e "\e[31m""\nThey are the following:\n"
    cat "$directory"/missing_sra_ids.txt
    echo -e "\nmissing_sra_ids.txt has been created in the -d directory and contains the missing SRA ids\n"
    echo -e "\nTry redownloading them using the missing_sra_ids.txt file as the -f input"
fi

# Set the colour back to normal
echo -e "\e[39m"

# Clean up
rm "$directory"/sra_ids.txt
rm "$directory"/cleanup_sra_ids.txt