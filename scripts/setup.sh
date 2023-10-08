#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
###############################################################################################################

# This script sets up a project with a specified structure in the provided root directory.
# It also moves all files from the current directory to the project's script directory 
# and replaces 'JCOM_pipeline' with the project name in file names and file contents.

# Root directory for all projects
root="jcomvirome"

# Project name
project="JCOM_pipeline_virome"

# email address
email="jmif9945@uni.sydney.edu.au"

# Define directory paths for convenience
project_dir="/project/${root}/${project}"
scratch_dir="/scratch/${root}/${project}"

# Create project directories in /project and /scratch
# The -p option creates parent directories as needed and doesn't throw an error if the directory already exists.
echo "Creating project directories..."
mkdir -p "${project_dir}"/{scripts,accession_lists,adapters,logs,environments,ccmetagen,blast_results,annotation,mapping,contigs/{final_logs,final_contigs},fastqc,read_count}
mkdir -p "${scratch_dir}"/{abundance,read_count,raw_reads,trimmed_reads}
mkdir -p "${scratch_dir}"/abundance/final_abundance

# Move all files from the current directory to the project's scripts directory
echo "Moving files to the project's scripts directory..."
mv ./* "${project_dir}/scripts"
mv ../environments/* "${project_dir}/environments/"
mv ../adapters/* "${project_dir}/adapters/"

# Navigate to the project's scripts directory
cd "${project_dir}/scripts"

# Rename files with project name substitution
echo "Renaming files with project name substitution..."
find . -type f -exec bash -c 'new_file="${1/JCOM_pipeline/$2}"; [ "$1" != "$new_file" ] && mv "$1" "$new_file"' _ {} "$project" \;

# Replace project-related variables in the script files
echo "Replacing project-related variables in the script files..."
sed -i "s/JCOM_pipeline_virome/$project/g" *
sed -i "s/JCOM_pipeline/$project/g" *
sed -i "s/jcomvirome/$root/g" *
sed -i "s/jmif9945@uni.sydney.edu.au/$email/g" *

# Notify user about the project and scratch directory paths
echo "Project setup completed successfully."
echo "Project directory: ${project_dir}"
echo "Scratch directory: ${scratch_dir}"