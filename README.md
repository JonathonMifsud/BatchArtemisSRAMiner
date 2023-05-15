## Installation

A repo containing tools and shortcuts for virus discovery workflows on Artemis with a particular focus on SRA mining.
If you run into any problems please don't hesitate to open an issue or shoot me an email `jmif9945@uni.sydney.edu.au`. Documentation is a work in progress so please let me know if I should add anything!


Download the BatchArtemisSRAMiner package:

1. Click the blue code button > Download .zip
2. Transfer a safe spot in Artemis
3. Unzip: `unzip BatchArtemisSRAMiner-main.zip`
4. `cd BatchArtemisSRAMiner-main/BatchArtemisSRAMiner/orig_scripts/; chmod +x ./*; nano setup.sh`
5. Change the `root`, `project` and `email` parameters. 
6. Run the setup script `./setup.sh`
7. `cd ../../../` and remove the install files `rm BatchArtemisSRAMiner-main BatchArtemisSRAMiner-main.zip`

Optional:
Add the commands to your path
`nano ~/.bashrc`
Add the line: 
`export PATH="/project/YOURROOT/YOURPROJECT/scripts/:$PATH"`

Make sure to change the variable names!

Then to load it: `source ~/.bashrc`


Each general task you want to run is associated with a .sh (shell) and .pbs script. The .sh script works as a wrapper, passing parameters and variables to the .pbs script. After setting up, you usually don't need to edit the .pbs script.

If you are unsure about what variables/files need to be passed to a script, refer to the .sh script.

The scripts are designed to process batches, so they require a list of filenames to run.

## Pipeline
The standard pipeline follows these steps:

1. Download SRA
2. Check the that the raw reads have downloaded by looking in /scratch/your_root/your_project/raw_reads . You can use the `check_sra_downloads.sh` script to do this! Re-download any that are missing (make a new file with the accessions) 
3. Trim Assembly Abundance
4. Check that all contigs are non-zero in size in `/project/your_root/your_project/contigs/final_contigs/`
6. Run blastxRdRp and blastxRVDB (these can be run simultaneously)
7. Concatenate all the RVDB and RdRp contigs across all libraries using cat, etc. 
The reason I do this is that it is expensive to run NT / NR blasts for each contig file because the giant databases have to be loaded in each time. Instead you concatentate all of the blast contigs together and run it once. 
E.g, `cat *_blastcontigs.fasta > combined.contigs.fa`
8. Move `combined.contigs.fa` to the `/project/your_root/your_project/contigs/final_contigs/` i.e. the input location for blasts. 
9. Create an input accession file containing `combined`
10. Run blastnr and blastnt using this input file. 
11. Generate a summary table (Anaconda is needed - see below). The summary table script will create several files inside `/project/your_root/your_project/blast_results/summary_table_creation`. The csv files are the summary tables - if another format or summary would suit you best let me know and we can sit down and develop it. 

The large files e.g., raw and trimmed reads and abundance files are stored in `/scratch/` while the smaller files tend to be in /project/


### Custom Blasts
The custom blast scripts are useful for running other blasts, but they require some adjustments to be compatible with the final summary table scripts.

### Monitoring Job Status

You can check the status of a job using `qstat -u USERNAME`. This will show you the status of the batch scripts. To check the status of individual subjobs within a batch, use `qstat -tx JOB_ID`.

### Job Status Shortcut
Replace jmif9945 with your unikey and run the following line to create an alias for `q`. This will display two panels: the top panel shows the last 100 jobs/subjobs, while the bottom panel provides a summary of batch jobs:

`alias q="qstat -Jtan1 -xu jmif9945 | tail -n100; qstat -u jmif9945"`
Enter q to check the job status. If you want to make this alias permanent, add it to your .bashrc file:

`nano ~/.bashrc`
Add the line: `alias q="qstat -Jtan1 -xu jmif9945 | tail -n100; qstat -u jmif9945"`

Then to load it: `source ~/.bashrc`

### Common Flags

Note: Flags can vary between scripts, so always check the individual `.sh` scripts. However, the common flags are as follows:

`-f` used to specify a file that contains the SRA run accessions to be processed. This option is followed by a string containing the complete path to a file containing accessions one per line. I typically store these files in `/project/your_root/your_project/accession_lists/`. If this option is not provided, most of the scripts in the pipeline will fail or excetue other behaviours (e.g., see the -f in `trim_assembly_abundance.sh`), as such I always recommmend setting the -f where able so you can better keep track of the libraries you are running. NOTE: The max number of SRAs I would put in a accession file is 1000. If you have more than this create two files and run the download_script twice. The limit is enforced by Artemis/PBS. 

**Less common**
`-i` The input option. This option is followed by a string that represents the input file for the script. This is used most commonly in the custom blast scripts where you are interested in a single input rather than an array of files. 
`-d` The database option. This option should be followed by a string that represents the complete path to a database against which blast will be run.

**Rarely need to change**
The way the pipeline is set up the values for root and project that you entered in the setup script are used as the default project (-p flag) and root (-r flag) values in all scripts.
There may be cases where you want to run these functions in directories outside of the normal pipeline structure. The blast custom scripts, mafft alignment and iqtree scripts are designed with this inmind. Input is specified using -i, while the output is the current WD. With other functions it may just be easier to redownload the github .zip file and rerun the setup script as described above - creating the folder sctruture and scripts for the new project.

`-p` The project option. This option should be followed by a string that represents the project name i.e. what you entered as project in the original setup script. 
`-r` The root project option. This option should be followed by a string that represents the root project name. Use e.g., -r VELAB or the value you entered for root in the original setup script. 

You only need to specify -p or -r if you are going outside of the directory stucture in which the setup.sh was ran for. 

## Troubleshooting

If your SRA fails, check the error and output logs in the logs folder in the project branch.

Downloading Failure
Downloads often time out, and while the script will attempt to download multiple times, it might eventually fail. If this happens, use the check_sra_downloads.sh script to identify which libraries failed. This script will generate a file that can be fed back into -f.

Other reasons for download failure could be invalid SRA run id or insufficient storage space in the directory.

Trimming/Assembly Failure
The most common cause of trimming/assembly failure is a corrupt download. In this case, it's best to remove, redownload, and reassemble the data.

### Non-SRA Libraries

You can also use the script with non-SRA libraries by cleaning the original raw read names. For example, `hope_valley3_10_HWGFMDSX5_CCTGCAACCT-CTGACTCTAC`

E.g., hope_valley3_10_HWGFMDSX5_CCTGCAACCT-CTGACTCTAC_L002_R1.fastq.gz -> hpv3t10_1.fastq.gz
The main thing is that underscores are only used to seperate the ID (hpv3t10) and the read file direction (1) and that the "R" in R1/2 is remove. 

## Installing Anaconda

Conda is a package manager that can be used to install packages that aren't readily available through the module. This is necessary because Artemis lacks some required modules/module versions. The primary use cases here are CCmetagen and the summary table script.

Download the Anaconda installer script from the Anaconda distribution site. You can use the wget command to download it.
`wget https://repo.anaconda.com/archive/Anaconda3-4.3.0-Linux-x86_64.sh`
`bash Anaconda3-4.3.0-Linux-x86_64.sh`


Press ENTER to continue and review the license agreement. Press `ENTER` again to move through the text. Once you've reviewed the license, type `yes` to agree to the terms.

The installer will prompt you for the location of the installation. As there is very limited space in your home directory (e.g., /home/jmif9945/) installing Anaconda here isn't a great idea. Instead install it in your main project home directory by specifying the path:
For example:
`/project/jcomvirome/anaconda3`
You can press `ENTER` to accept.

At the end of the installation, you'll be asked if you want to run conda init. We recommend saying `yes` to this option. This will make Anaconda usable from any terminal session.

Activate Installation
Close and re-open your terminal. You should now have access to the conda command.

Errors during conda installation:


To create the environments:
`conda env create -f /project/VELAB/jcom_pipeline_taxonomy/ccmetagen_env.yml`
`conda env create -f /project/VELAB/jcom_pipeline_taxonomy/project_pipeline.yml`
`conda env create -f /project/VELAB/jcom_pipeline_taxonomyr_env.yml`


### Storage:
I tend to delete the raw and trimmed read files after contigs are the trim_assembly_abundance script has completed as abundance and read count information has been calculated at this stage. Once the summary table is created there are a couple large files in this directory including the concatentated abundance table. This can be remade so consider removing this if you are low on storage. 

