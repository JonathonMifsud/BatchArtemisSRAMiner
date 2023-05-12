## Installation

Download the BatchArtemisSRAMiner package:

1. Click the blue code button > Download .zip
2. Transfer a safe spot in Artemis
3. Unzip: `unzip BatchArtemisSRAMiner-main.zip`
4. `cd BatchArtemisSRAMiner-main/BatchArtemisSRAMiner/orig_scripts/ chmod +x ./*; nano setup.sh`
5. Change the `root`, `project` and `email` parameters. 
6. Run the setup script `./setup.sh`


Each general task you want to run is associated with a .sh (shell) and .pbs script. The .sh script works as a wrapper, passing parameters and variables to the .pbs script. After setting up, you usually don't need to edit the .pbs script.

If you are unsure about what variables/files need to be passed to a script, refer to the .sh script.

The scripts are designed to process batches, so they require a list of filenames to run.

## Pipeline
The standard pipeline follows these steps:

1. Download SRA
2. Trim Assembly Abundance
3. Run blastxRdRp and blastxRVDB (these can be run simultaneously)
4. Concatenate all the RVDB and RdRp contigs across all libraries using cat, etc.
5. Run blastnr and blastnt
6. Generate a summary table


### Custom Blasts
The custom blast scripts are useful for running other blasts, but they require some adjustments to be compatible with the final summary table scripts.

### Monitoring Job Status

You can check the status of a job using `qstat -u USERNAME`. This will show you the status of the batch scripts. To check the status of individual subjobs within a batch, use `qstat -tx JOB_ID`.

###Job Status Shortcut
Replace jmif9945 with your unikey and run the following line to create an alias for `q`. This will display two panels: the top panel shows the last 100 jobs/subjobs, while the bottom panel provides a summary of batch jobs:

`alias q="qstat -Jtan1 -xu jmif9945 | tail -n100; qstat -u jmif9945"`
Enter q to check the job status. If you want to make this alias permanent, add it to your .bashrc file:

`nano ~/.bashrc`
Add the line: `alias q="qstat -Jtan1 -xu jmif9945 | tail -n100; qstat -u jmif9945"`

Then to load it: `source ~/.bashrc`

### Common Flags

Note: Flags can vary between scripts, so always check the individual .sh scripts. However, the common flags are as follows:

TO BE ADDED

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
`wget https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh`
`bash Anaconda3-2023.03-1-Linux-x86_64.sh`


Press ENTER to continue and review the license agreement. Press `ENTER` again to move through the text. Once you've reviewed the license, type `yes` to agree to the terms.

The installer will prompt you for the location of the installation. You can press `ENTER` to accept the default location or specify a different location.

At the end of the installation, you'll be asked if you want to run conda init. We recommend saying `yes` to this option. This will make Anaconda usable from any terminal session.

Activate Installation
Close and re-open your terminal. You should now have access to the conda command.

To create the environments:
`conda env create -f /project/VELAB/jcom_pipeline_taxonomy/ccmetagen_env.yml`
`conda env create -f /project/VELAB/jcom_pipeline_taxonomy/project_pipeline.yml`
`conda env create -f /project/VELAB/jcom_pipeline_taxonomyr_env.yml`
