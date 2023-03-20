#!/bin/bash

# Setup script to create a project folder and subfolders to run the batch pipeline

# Root folder for all projects
root="jcomvirome" # this is your RDS project name, it could be VELAB if you want everything to run there

# Provide a project name as a string
project="JCOM_pipeline_virome" # this is the name of the project folder you want to create

mkdir /project/"$root"/"$project"/
mkdir /project/"$root"/"$project"/scripts
mkdir /project/"$root"/"$project"/accession_lists
mkdir /scratch/"$root"/"$project"/
mkdir /project/"$root"/"$project"/adapters
mkdir /project/"$root"/"$project"/logs
mkdir /project/"$root"/"$project"/ccmetagen
mkdir /project/"$root"/"$project"/blast_results
mkdir /project/"$root"/"$project"/annotation
mkdir /project/"$root"/"$project"/mapping
mkdir /project/"$root"/"$project"/contigs
mkdir /project/"$root"/"$project"/contigs/final_logs
mkdir /project/"$root"/"$project"/contigs/final_contigs
mkdir /project/"$root"/"$project"/fastqc
mkdir /project/"$root"/"$project"/read_count
mkdir /scratch/"$root"/"$project"/abundance
mkdir /scratch/"$root"/"$project"/read_count
mkdir /scratch/"$root"/"$project"/raw_reads
mkdir /scratch/"$root"/"$project"/trimmed_reads
