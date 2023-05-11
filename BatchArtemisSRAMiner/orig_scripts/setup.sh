#!/bin/bash

# This script sets up a project with a specified structure in the provided root directory.
# It also moves all files from the current directory to the project's script directory 
# and replaces 'JCOM_pipeline' with the project name in file names and file contents.

# Root directory for all projects
root="jcomvirome"

# Project name
project="JCOM_pipeline_virome"

# Define directory paths for convenience
project_dir="/project/${root}/${project}"
scratch_dir="/scratch/${root}/${project}"

# Create project directories in /project and /scratch
# The -p option creates parent directories as needed and doesn't throw an error if the directory already exists.
mkdir -p "${project_dir}"/{scripts,accession_lists,adapters,logs,ccmetagen,blast_results,annotation,mapping,contigs/{final_logs,final_contigs},fastqc,read_count}
mkdir -p "${scratch_dir}"/{abundance,read_count,raw_reads,trimmed_reads}

# Move all files from the current directory to the project's scripts directory
mv ./* "${project_dir}/scripts"

# Navigate to the project's scripts directory
cd "${project_dir}/scripts"

# Replace 'JCOM_pipeline' with the project name in file names
find . -type f | while read -r file; do
    mv "$file" "$(echo "$file" | sed "s/JCOM_pipeline/$project/g")"
done

# Replace 'JCOM_pipeline' with the project name in file contents
find . -type f -name '*' -exec sed -i "s/JCOM_pipeline/$project/g" {} \;
