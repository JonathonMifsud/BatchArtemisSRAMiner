### BatchArtemisSRAMiner

## Instructions 

### Installation:

Unzip, add your details to the setup script and run.

### General:

For each of the general tasks we want to run there you will find a .sh (shell) and a pbs scripts. There are more scripts then currently included so if you are after anything else let me know. The .sh script is essentially a wrapper that tells the .pbs the parameters and variables to run. For the most part after setup you shouldn't need to edit the .pbs script. 

If you are ever confused about what variables/files you need to pass to a script check out the .sh script. 

For the most part the scripts are set up in a batch format and will require a list of filenames to run .

### Checking job status
When you check a jobs status using qstat -u USERNAME you will find that there is only one job for the entire batch scripts (e.g., 6804265[])
To check the current status of the indivdual subjobs inside this you can run qstat -tx JOB_ID

*A use a little shortcut to check job status:*
If you run the following line - replacing jmif9945 with your unikey you will see two panels - it will create an alias for 'q', the top will show the last 100 jobs+subjobs while the bottom panel is a summary collapsing batch jobs. 
alias q="qstat -Jtan1 -xu jmif9945 | tail -n100; qstat -u jmif9945"
Type 'q' and enter
If you like this and want to make it permenate you will have to add that line to your .bashrc file
nano ~/.bashrc
Add the line
source ~/.bashrc

### Common flags and their descriptions
NOTE: This varies between scripts so always check the indivdual .sh scripts but for the most part the flags are the following:



### Why is my SRA failing at:

You can find error and output logs in the logs folder in the project branch. 

Downloading - 
    this is the most common occurence - downloads time out all the time, the script will try the download multiple times but eventually will fail. If this occurs use the check_sra_downloads.sh script to figure out which libraries failed. It will create a nice file for you that can be fed straight back into -f. 
    Other reasons downloads could be failing is that you haven't provide a valid SRA run id or the dir has run out of room. 

Trimming/Assembly - 
    Most likely a corrupt download, best to remove, redownload and reassemble. With the state of the defaultQ these days it is also possible that the job will time out. This can occasionally happen if the batch script as a whole has been running for too long. 

### Using the script with non SRA libraries
The script can be run with non SRA libraries if the original raw read names are cleaned
E.g., hope_valley3_10_HWGFMDSX5_CCTGCAACCT-CTGACTCTAC_L002_R1.fastq.gz -> hpv3t10_1.fastq.gz
The main thing is that underscores are only used to seperate the ID (hpv3t10) and the read file direction (1) and that the "R" in R1/2 is remove. 

