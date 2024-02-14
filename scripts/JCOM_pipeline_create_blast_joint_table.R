#!/usr/bin/env Rscript

# Jonathon Mifsud
# University of Sydney

# This script takes the blast results from the JCOM pipeline and creates a
# summary table of the results. It also extracts the taxids from the blast
# results and outputs them to a separate file
# This script is designed to be run on the command line using Rscript
# All dependencies are installed during _summary_table.sh

# Packages ---------------------------------------------------------------------
suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"
suppressPackageStartupMessages(require(dplyr))
suppressPackageStartupMessages(require(vroom))
suppressPackageStartupMessages(require(purrr))
suppressPackageStartupMessages(require(stringr))
suppressPackageStartupMessages(require(tidyr))
suppressPackageStartupMessages(require(readr))

# Functions --------------------------------------------------------------------
blastSortByEvalue <- function(blastTable) {
  # input a blast txt results delim file
  # formatted as so -f 6 qseqid qlen sseqid stitle pident length evalue
  # col.names = c("contig", "length", "accession", "desc", "ident", "region", "evalue"))
  blastTable_sorted <- blastTable[order(blastTable$evalue, decreasing = TRUE),]
  return(blastTable_sorted)
}
blastGetTopHit <- function(blastTable) {
  require(dplyr)
  # input a blast txt results delim file
  # formatted as so -f 6 qseqid qlen sseqid stitle pident length evalue
  # col.names = c("contig", "length", "accession", "desc", "ident", "region", "evalue"))
  blastTable_tophit <- blastTable %>%
    group_by(contig) %>%
    filter(evalue == min(evalue)) %>%
    ungroup()
  return(blastTable_tophit)
}

blastCreateJoinTable <- function(nr_table,
                                 nt_table,
                                 rdrp_table,
                                 rvdb_table,
                                 abundance_table,
                                 readcount_table,
                                 rdrp_taxonomy,
                                 rvdb_taxonomy){
  # format table 1 NR
  table_nr <- blastGetTopHit(nr_table) %>%
    rename_all( ~ paste0("nr_", .x)) %>%
    select(-nr_region, -nr_length) %>%
    distinct(nr_contig, .keep_all = T)

  # format table 2 NT
  table_nt <- blastGetTopHit(nt_table) %>%
    rename_all( ~ paste0("nt_", .x)) %>%
    select(-nt_length) %>%
    distinct(nt_contig, .keep_all = T)

  # format table 3 RdRp
  table_rdrp <- blastGetTopHit(rdrp_table) %>%
    rename_all( ~ paste0("rdrp_", .x)) %>%
    select(-rdrp_region, -rdrp_length) %>%
    distinct(rdrp_contig, .keep_all = T)

  # format table 4 RVDB
  table_rvdb <- blastGetTopHit(rvdb_table) %>%
    rename_all( ~ paste0("rvdb_", .x)) %>%
    select(-rvdb_region, -rvdb_length) %>%
    distinct(rvdb_contig, .keep_all = T)

  # format table 4 Abundance
  table_abundance <- abundance_table %>%
    filter(!length == "length") %>%
    select(contig, length, expected_count, FPKM) %>%
    mutate(library = str_extract(contig, "len\\d+_.*")) %>%
    mutate(library = str_remove_all(library, "len\\d+_"))

  # adding read count
  table_readcount <- readcount_table %>%
    distinct() %>%
    mutate(library = str_remove_all(library, "_trimmed.*")) %>%
    group_by(library) %>%
    mutate(read_count = as.numeric(read_count)) %>%
    mutate(paired_read_count = sum(read_count)) %>%
    ungroup() %>%
    distinct(library, paired_read_count)

  # adding taxonomy
  table_rdrp <- table_rdrp %>%
    mutate(rdrp_accession = case_when(!rdrp_accession %in% rdrp_taxonomy$protein_accession ~ as.character(.$rdrp_desc),
                                      TRUE ~ as.character(.$rdrp_accession))) %>%
    left_join(rdrp_taxonomy, by = c("rdrp_accession" = "protein_accession")) %>%
    select(rdrp_contig, rdrp_accession, rdrp_desc, rdrp_ident, rdrp_evalue, viral_taxa, taxid, host_species, source) %>%
    rename(rdrp_viral_taxa = viral_taxa, rdrp_taxid = taxid, rdrp_host_species = host_species, rdrp_source = source)

  table_rvdb <- table_rvdb %>%
    left_join(rvdb_taxonomy, by = c("rvdb_desc" = "join_column")) %>%
    select(rvdb_contig, protein_accession, organism, rvdb_ident, rvdb_evalue, genomic_region, taxid) %>%
    rename(rvdb_protein_accession = protein_accession, rvdb_organism = organism, rvdb_genomic_region = genomic_region, rvdb_taxid = taxid)

  # create final table
  full_table <- table_abundance %>%
    mutate(length = as.numeric(length),
           expected_count = as.numeric(expected_count),
           FPKM = as.numeric(FPKM)) %>%
    left_join(table_readcount, by = "library") %>%
    filter(contig %in% table_rdrp$rdrp_contig | contig %in% table_rvdb$rvdb_contig) %>%
    mutate(standarised_abundance_proportion = expected_count/paired_read_count) %>%
    full_join(table_rdrp, by = c("contig" = "rdrp_contig")) %>%
    left_join(table_rvdb, by = c("contig" = "rvdb_contig")) %>%
    left_join(table_nt, by = c("contig" = "nt_contig")) %>%
    left_join(table_nr, by = c("contig" = "nr_contig")) %>%
    distinct(.keep_all = T)

  return(full_table)
}

blastExtractTaxidFromJoinTable <- function(blast_join_table){
  # extract all the taxids across the 4 blasts from the blast join table
  # produced by blastCreateJoinTable
  taxids <- blast_join_table %>%
    select(rdrp_taxid, rvdb_taxid, nr_taxid, nt_taxid) %>%
    # occasionally there are multiple taxid assigned to a hit
    # i.e. dingo and dog
    # we just want to grab the first one as we are only concerned if it is
    # a virus or not
    mutate_all(funs(str_replace_all(., "\\;.*", ""))) %>%
    mutate_if(is.character, as.numeric, na.rm = F) %>%
    pivot_longer(cols = everything(), values_to = "taxid", names_to = "source") %>%
    select(-source) %>%
    distinct() %>%
    drop_na()

  return(taxids)
}


# Options ----------------------------------------------------------------------
option_list = list(
  make_option(c("-p", "--nr"), action="store", default=NA, type='character',
              help="Path to Protein database blast output"),
  make_option(c("-t", "--nt"), action="store", default=NA, type='character',
              help="Path to Nucleotide database blast output"),
  make_option(c("-r", "--rdrp"), action="store", default=NA, type='character',
              help="Path to RdRp blast output"),
  make_option(c("-v", "--rvdb"), action="store", default=NA, type='character',
              help="Path to RdRp blast output"),
  make_option(c("-a", "--abundance"), action="store", default=NA, type='character',
              help="Path to RSEM abundance file,\nNOTE: this script assumes that your abundance contig names match those in the blast output\n
              ie. if your blast results contain _len765 at the end of each contig so should your abundance results"),
  make_option(c("-c", "--readcounts"), action="store", default=NA, type='character',
              help="Path to read counts for libraries created using project_read_count.sh"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Name of the output csv file, e.g. SRR1234142_summary_results \n
              EXAMPLE USAGE: Rscript create_blast_summary_table.R --nr ERS1829347.nr.txt --rdrp ERS1829347.rdrp.txt --nt ERS1829347.nt.txt --abundance RSEM.isoforms.results.revised --output summary_table.csv"),
  make_option("--rdrp_tax", action="store", default=NA, type='character',
              help="Path to ID table"),
  make_option("--rvdb_tax", action="store", default=NA, type='character',
              help="Path to ID table"),
  make_option(c("-m", "--multi_lib"), action="store_true", default=FALSE,
              help="Are there contigs from multiple libraries that you would like to extract as a row"))

opt <- parse_args(OptionParser(option_list=option_list))


# Read in files ----------------------------------------------------------------
if (!is.na(opt$nr)){
  nr_table <- vroom(opt$nr,
                         col_names = c("contig", "length", "accession", "desc", "taxid", "ident", "region", "evalue"),
                    delim = "\t",
                    show_col_types = FALSE)
} else {
  message("Missing --nr flag. Command will fail")
  nr_table <- ""
}

if (!is.na(opt$nt)){
  nt_table <- vroom(opt$nt,
                         col_names = c("contig", "length","accession", "desc", "taxid", "ident",  "length2", "evalue"),
                    delim = "\t",
                    show_col_types = FALSE)
} else {
  message("Missing --nt flag. Command will fail")
  nt_table <- ""
}

if (!is.na(opt$rdrp)){
  rdrp_table <- vroom(opt$rdrp,
                  col_names = c("contig", "length", "accession", "desc", "ident", "region", "evalue"),
                  delim = "\t",
                  show_col_types = FALSE)
} else {
  message("Missing --rdrp flag. Command will fail")
  rdrp_table <- ""
}

if (!is.na(opt$rvdb)){
  rvdb_table <- vroom(opt$rvdb,
                      col_names = c("contig", "length", "accession", "desc", "ident", "region", "evalue"),
                      delim = "\t",
                      show_col_types = FALSE)
} else {
  message("Missing --rvdb flag. Command will fail")
  rvdb_table <- ""
}

if (!is.na(opt$abundance)){
  abundance_table <- vroom(opt$abundance,
                           col_names = c("contig", "gene_id", "length", "effective_length", "expected_count","TPM","FPKM","IsoPct"),
                           show_col_types = FALSE)
} else {
  message("Missing --abundance flag. Command will fail")
  abundance_table <- ""
}

if (!is.na(opt$readcounts)){
  readcount_table <- vroom(opt$readcounts,
                           show_col_types = FALSE,
                           delim = "\\n",
                            col_names = F) %>%
    pivot_longer(cols = everything(), values_to = "library") %>%
    mutate(read_count = as.numeric(word(library, 2, sep = ",")),
           library = word(library, 1, sep = ",")) %>%
    select(library, read_count) %>%
    drop_na()
} else {
  message("Missing --readcounts flag. Command will fail")
  readcount_table <- ""
}


if (!is.na(opt$rdrp_tax)){
  rdrp_taxonomy <- vroom(opt$rdrp_tax,
                           col_names = c("protein_accession", "viral_taxa", "description", "taxid", "host_species", "source"),
                         show_col_types = FALSE)[-1,]
} else {
  message("Missing --rdrp_tax flag. Command will fail")
  rdrp_taxonomy <- ""
}

if (!is.na(opt$rvdb_tax)){
  rvdb_taxonomy <-  vroom(opt$rvdb_tax,
                          col_names = c("join_column","source","protein_accession","source2","nucl","genomic_region","organism","taxid"),
                          show_col_types = FALSE,
                          delim = "|") %>% 
    mutate(join_column = str_replace_all(join_column, "\\%", "\\|"))
} else {
  message("Missing --rvdb_tax flag. Command will fail")
  rvdb_taxonomy <- ""
}

# Run Block --------------------------------------------------------------------
blast_join_table <- blastCreateJoinTable(nr_table,
                           nt_table,
                           rdrp_table,
                           rvdb_table,
                           abundance_table,
                           readcount_table,
                           rdrp_taxonomy,
                           rvdb_taxonomy)
taxids <- blastExtractTaxidFromJoinTable(blast_join_table)
message("output path is", opt$output)
glimpse(taxids)
glimpse(blast_join_table)
write_delim(taxids, paste0(opt$output, "_taxids"), col_names = F)
write_csv(blast_join_table, opt$output)
