#! /usr/bin/env Rscript

###########################################################################
##                          CONFIGURE PROGRAM                            ##
###########################################################################
options(stringsAsFactors = F)

# Load necessary packages
suppressPackageStartupMessages(require(optparse))        # Parse script inputs

# Prepare input commands
option_list <- list(
  make_option(c("-n", "--hpoloci"), action="store", type="character",
              help="File with network HPO - Loci"),
  make_option(c("-l","--locigenes"), action="store", type = "character",
              help="File with network Loci - Genes"),
  make_option(c("-o","--output"), action="store",type="character",
              dest="output", help="Destiny file")
)

opt <- parse_args(OptionParser(option_list=option_list))

###########################################################################
##                          LOAD & TRANSFORM                             ##
###########################################################################

# Load both files
locis_hpo   <- read.table(file = opt$hpoloci, header = F, stringsAsFactors = F, sep = "\t")
locis_genes <- read.table(file = opt$locigenes, header = F, stringsAsFactors = F, sep = "\t")

# Per each loci, generate link HPO - Gene
hpo_genes <- as.data.frame(do.call(rbind,lapply(unique(locis_hpo[,1]), function(loci){
  # Find locis index into both sets
  hpo_indx <- which(locis_hpo[,1] == loci)
  gen_indx <- which(locis_genes[,1] == loci)
  # Concatenate HPO-Gene
  info <- data.frame(HPO  = unlist(lapply(hpo_indx, function(i){return(rep(locis_hpo[i,2],length(gen_indx)))})),
                     Gene = rep(locis_genes[gen_indx,2],length(hpo_indx)),
                     stringsAsFactors = F)
  # return
  return(info)
})))

# Sort by HPO
hpo_genes <- hpo_genes[order(hpo_genes[,1],hpo_genes[,2]),]

# Write file into output file
write.table(hpo_genes, file = opt$output, sep = "\t", quote = F, col.names = F, row.names = F)
