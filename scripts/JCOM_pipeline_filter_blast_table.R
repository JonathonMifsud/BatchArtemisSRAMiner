#!/usr/bin/env Rscript

# Jonathon Mifsud
# University of Sydney

# This script takes the output of the blast table and filters it based on the
# taxonomy table. Using the results of the 4 blasts it will classify the contigs as either Likely Viruses, Potential-Viruses
# or Non-Viral outputting seperate csv tables for each classification.

# Packages ---------------------------------------------------------------------
suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"
suppressPackageStartupMessages(require(dplyr))
suppressPackageStartupMessages(require(vroom))
suppressPackageStartupMessages(require(purrr))
suppressPackageStartupMessages(require(stringr))
suppressPackageStartupMessages(require(tidyr))
suppressPackageStartupMessages(require(readr))

# Options ----------------------------------------------------------------------
option_list = list(
  make_option(c("-t", "--taxnomy_table"), action="store", default=NA, type='character',
              help="Path to Protein database blast output"),
  make_option(c("-b", "--blast_table"), action="store", default=NA, type='character',
              help="Path to Nucleotide database blast output"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Name of the output path and file, e.g. /myresults/SRR1234142_summary_results"))

opt <- parse_args(OptionParser(option_list=option_list))

# Functions --------------------------------------------------------------------
summariseTaxTable <- function(taxnomy_table){
  taxnomy_table_summarised <- taxnomy_table %>%
    mutate(group = case_when(str_detect(genus, regex("unclassified.*genus")) ~ paste0(as.character(.$order), ";", as.character(.$family)),
                             TRUE ~ paste0(as.character(.$order), ";", as.character(.$family), ";", as.character(.$genus)))) %>%
    mutate(group = case_when(family == "unclassified Viruses family" ~ as.character(.$order),
                             TRUE ~ as.character(.$group))) %>%
    mutate(group = case_when(order == "unclassified Viruses order" ~ as.character(.$class),
                             TRUE ~ as.character(.$group))) %>%
    mutate(group = case_when(class == "unclassified Viruses class" ~ as.character(.$phylum),
                             TRUE ~ as.character(.$group))) %>%
    mutate(group = case_when(phylum == "unclassified Viruses phylum" ~ as.character(.$kingdom),
                             TRUE ~ as.character(.$group))) %>%
    mutate(group = str_trim(str_remove_all(group, regex("genus|species|family|order|class|phylum|unclassified")))) %>%
    mutate(taxid = as.numeric(taxid)) %>%
    select(taxid,kingdom,lineage,group)

  return(taxnomy_table_summarised)

}
createVirusFolderDF <- function(blastoutput_table){
  # given e.g. likely_viruses or potential viruses it will summarise the
  # taxonomy information and create a df containing contig name and destination
  blastoutput_table <- read.csv(blastoutput_table)
  virus_folder_scaffold <- blastoutput_table %>%
    select(contig, rdrp_group, rvdb_group, nr_group, nt_group) %>%
    mutate(destination = case_when(!is.na(rdrp_group) ~ as.character(.$rdrp_group),
                                   (is.na(rdrp_group) & !is.na(nr_group)) ~ as.character(.$nr_group),
                                   (is.na(rdrp_group) & is.na(nr_group) & !is.na(rvdb_group)) ~ as.character(.$rvdb_group),
                                   (is.na(rdrp_group) & is.na(nr_group) & is.na(rvdb_group)) ~ as.character(.$nt_group))) %>%
    mutate(destination = str_replace_all(destination, "\\; .*", "")) %>%
    select(contig, destination)

  return(virus_folder_scaffold)


}
filterBlastTable <- function(blast_table, taxnomy_table_summarised){

  blast_table_with_taxa <- blast_table %>%
    # NR AND NT ARE NON_VIRUSES WHEN NA FOR SOME REASON
    #where multiple taxid choose one as we arent concerned at such a minute taxa level (ie. we are only concerned about kingdom level)
    mutate_at(c("rdrp_taxid", "nt_taxid", "nr_taxid", "rvdb_taxid"), funs(str_replace_all(., "\\;.*", ""))) %>%
    mutate(rdrp_taxid = as.numeric(rdrp_taxid),
          nt_taxid = as.numeric(nt_taxid),
          nr_taxid = as.numeric(nr_taxid),
          rvdb_taxid = as.numeric(rvdb_taxid)) %>%
    left_join(taxnomy_table_summarised, by = c("rdrp_taxid" = "taxid")) %>%
    mutate(rdrp_kingdom = case_when(!is.na(rdrp_accession) ~ "Viruses"),
           rdrp_group = case_when(is.na(group) ~ as.character(.$rdrp_viral_taxa),
                                  group == "Viruses" ~ as.character(.$rdrp_viral_taxa),
                                           TRUE ~ paste0(as.character(.$rdrp_viral_taxa), ";", group))) %>%
    select(-group, -lineage, -kingdom) %>%
    left_join(taxnomy_table_summarised, by = c("nt_taxid" = "taxid")) %>%
    mutate(nt_kingdom = case_when((!is.na(nt_accession) & kingdom == "Viruses") ~ "Viruses",
                                  (!is.na(nt_accession) & kingdom != "Viruses")  ~ "Non-Viral")) %>%
    rename(nt_group = group) %>%
    select(-lineage, -kingdom) %>%
    left_join(taxnomy_table_summarised, by = c("nr_taxid" = "taxid")) %>%
    mutate(nr_kingdom = case_when((!is.na(nr_accession) & kingdom == "Viruses") ~ "Viruses",
                                  (!is.na(nr_accession) & kingdom != "Viruses")  ~ "Non-Viral")) %>%
    rename(nr_group = group) %>%
    select(-lineage, -kingdom) %>%
    left_join(taxnomy_table_summarised, by = c("rvdb_taxid" = "taxid")) %>%
    mutate(rvdb_kingdom = case_when(!is.na(rvdb_protein_accession) ~ "Viruses")) %>%
    rename(rvdb_group = group) %>%
    select(contig, length, library, FPKM, standarised_abundance_proportion,
           rdrp_accession, rdrp_desc, rdrp_ident, rdrp_evalue, rdrp_taxid, rdrp_host_species, rdrp_source, rdrp_viral_taxa, rdrp_group, rdrp_kingdom,
           rvdb_protein_accession, rvdb_organism, rvdb_ident, rvdb_evalue, rvdb_taxid, rvdb_genomic_region, rvdb_group, rvdb_kingdom,
           nr_accession, nr_desc, nr_ident, nr_evalue, nr_taxid, nr_group, nr_kingdom,
           nt_accession, nt_desc, nt_ident, nt_evalue, nt_taxid, nt_group, nt_kingdom)

  classfied_blast_table <- blast_table_with_taxa %>%
    mutate(collective_classiciation = case_when(
      # Rdrp == virus, the rest equal virus or are missing = Virus
      (rdrp_kingdom == "Viruses" & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & (nr_kingdom == "Viruses" | is.na(nr_kingdom)) & (nt_kingdom == "Viruses" | is.na(nt_kingdom))) ~ "Viruses",
      # RVDB == virus, RdRp is na or Virus and one reference base is virus
      ((rdrp_kingdom == "Viruses" | is.na(rdrp_kingdom)) & rvdb_kingdom == "Viruses" & ((nr_kingdom == "Viruses" & is.na(nt_kingdom)) | (is.na(nr_kingdom) & nt_kingdom == "Viruses"))) ~ "Viruses",
      # When RdRp is na but everything else is virus
      (is.na(rdrp_kingdom) & rvdb_kingdom == "Viruses" & nr_kingdom == "Viruses" & nt_kingdom == "Viruses") ~ "Viruses",
      # When one or more of the virus databases == virus and NR says virus but NT says not virus = Potential-Viruses
      ((rdrp_kingdom == "Viruses" | is.na(rdrp_kingdom)) & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & nr_kingdom == "Viruses" & nt_kingdom == "Non-Viral") ~ "Potential-Viruses",
      # When one or more of the virus databases == virus and NT says virus but NR says not virus = Potential-Viruses
      ((rdrp_kingdom == "Viruses" | is.na(rdrp_kingdom)) & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & nr_kingdom == "Non-Viral" & nt_kingdom == "Viruses") ~ "Potential-Viruses",
      # When RVDB is virus and the rest are NA = Potential-Viruses
      (is.na(rdrp_kingdom) & rvdb_kingdom == "Viruses" & (is.na(nr_kingdom) & is.na(nt_kingdom))) ~ "Potential-Viruses",
      # When RdRp is na but everything else is virus
      (is.na(rdrp_kingdom) & rvdb_kingdom == "Viruses" & nr_kingdom == "Viruses" & nt_kingdom == "Viruses") ~ "Viruses",
      # alot of the false positive are these recurrent bacterium with no taxid link this should take care of most of them.
      ((rdrp_kingdom == "Viruses" | is.na(rdrp_kingdom)) & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & is.na(nr_kingdom) & is.na(nt_kingdom) & str_detect(nr_desc, "bacterium")) ~ "Non-Viral",
      # is NR is na we need to be careful about trusting the contig
      ((rdrp_kingdom == "Viruses" & is.na(nr_kingdom)) & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & (nt_kingdom == "Viruses" | is.na(nt_kingdom))) ~ "Potential-Viruses",
      # When both reference databases are non-viral = not viral
      ((rdrp_kingdom == "Viruses" | is.na(rdrp_kingdom)) & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & nr_kingdom == "Non-Viral" & nt_kingdom == "Non-Viral") ~ "Non-Viral",
      # When one reference database is non-viral and the other is missing = not viral
      ((rdrp_kingdom == "Viruses" | is.na(rdrp_kingdom)) & (rvdb_kingdom == "Viruses" | is.na(rvdb_kingdom)) & ((nr_kingdom == "Non-Viral" & is.na(nt_kingdom)) | (is.na(nr_kingdom) & nt_kingdom == "Non-Viral"))) ~ "Non-Viral"))


  likely_viruses <- classfied_blast_table %>%
    filter(collective_classiciation == "Viruses") %>%
    select(-collective_classiciation)
  potential_viruses <- classfied_blast_table %>%
    filter(collective_classiciation == "Potential-Viruses") %>%
    select(-collective_classiciation)
  not_viruses <- classfied_blast_table %>%
    filter(collective_classiciation == "Non-Viral") %>%
    select(-collective_classiciation)
  other <- classfied_blast_table %>%
    filter(is.na(collective_classiciation) | (collective_classiciation != "Non-Viral" &
             collective_classiciation != "Potential-Viruses" &
             collective_classiciation != "Viruses")) %>%
    select(-collective_classiciation)

  if(nrow(likely_viruses) >= 1){
    message(nrow(likely_viruses), " rows were classified as Viruses and written to ", paste0(opt$output, "_likely_viruses.csv"))
    write.csv(x = likely_viruses, file = paste0(opt$output, "_likely_viruses.csv"), row.names = F)
  }

  if(nrow(potential_viruses) >= 1){
    message(nrow(potential_viruses), " rows were classified as Potential Viruses and written to ", paste0(opt$output, "_potential_viruses.csv"))
    write.csv(x = potential_viruses, file = paste0(opt$output, "_potential_viruses.csv"), row.names = F)
  }

  if(nrow(not_viruses) >= 1){
    message(nrow(not_viruses), " rows were classified as Non-Viral and written to ", paste0(opt$output, "_non_viral.csv"))
    write.csv(x = not_viruses, file = paste0(opt$output, "_non_viral_viruses.csv"), row.names = F)
  }

  if(nrow(other) >= 1){
    message(nrow(other), " rows were classified as other i.e. a problem with the classification - check the collective_classiciation column. File containing these row is written to ", paste0(opt$output, "_other.csv"))
    write.csv(x = other, file = paste0(opt$output, "_other_viruses.csv"), row.names = F)
  }
}


# Loading in files -------------------------------------------------------------
if (!is.na(opt$taxnomy_table)){
  taxnomy_table <- vroom(opt$taxnomy_table,
                    col_names = c("taxid","lineage","kingdom","phylum","class","order","family","genus","species"),
                    delim = "\t",
                    show_col_types = FALSE)[-1,]
} else {
  message("Missing --taxnomy_table flag. Command will fail")
  taxnomy_table <- ""
}

if (!is.na(opt$blast_table)){
  blast_table <- vroom(opt$blast_table,
                    col_names = c("contig","length","expected_count","FPKM","library","paired_read_count","standarised_abundance_proportion","rdrp_accession","rdrp_desc","rdrp_ident","rdrp_evalue","rdrp_viral_taxa","rdrp_taxid","rdrp_host_species","rdrp_source","rvdb_protein_accession","rvdb_organism","rvdb_ident","rvdb_evalue","rvdb_genomic_region","rvdb_taxid","nt_accession","nt_desc","nt_taxid","nt_ident","nt_length2","nt_evalue","nr_accession","nr_desc","nr_taxid","nr_ident","nr_evalue"),
                    delim = ",",
                    show_col_types = FALSE)[-1,]
} else {
  message("Missing --blast_table flag. Command will fail")
  blast_table <- ""
}

# Run Block --------------------------------------------------------------------
taxnomy_table_summarised <- summariseTaxTable(taxnomy_table)
filterBlastTable(blast_table = blast_table, taxnomy_table_summarised = taxnomy_table_summarised)

tableType <- "likely_viruses"
likely_viruses_folder_scaffold <- createVirusFolderDF(paste0(opt$output, "_", tableType, ".csv"))
write_csv(likely_viruses_folder_scaffold, paste0(opt$output, "_", tableType, "_table_scaffold.csv"))

tableType <- "potential_viruses"
potential_viruses_folder_scaffold <- createVirusFolderDF(paste0(opt$output, "_", tableType, ".csv"))
write_csv(potential_viruses_folder_scaffold, paste0(opt$output, "_", tableType, "_table_scaffold.csv"))
