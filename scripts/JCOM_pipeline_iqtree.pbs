#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
###############################################################################################################

#PBS -M jmif9945@uni.sydney.edu.au
#PBS -l select=1:ncpus=10:mem=20GB
#PBS -N iqtree

# Module load
module load iqtree/2.1.7-beta

wd="$(dirname "${alignment}")"             # working dir 
filename="$(basename -- "$alignment")" # filename to be used in outfile
outpath="$wd"          # location of SRA files to be downloaded to
# cd working dir
cd "$wd" || exit

# Create a copy of the input alignment with the value of the -m flag prior to the date
file_basename="${filename%.*}"
file_extension="${filename##*.}"

# Remove any extra periods from the file_basename
file_basename_cleaned="${file_basename//.}"

new_filename="${file_basename_cleaned}_${model}.${file_extension}"
cp "$alignment" "$new_filename"

# Run iqtree with the new alignment filename
iqtree -s "$new_filename" -st AA -m "$model" -bb 1000 --mem 90% -alrt 1000 -T AUTO
