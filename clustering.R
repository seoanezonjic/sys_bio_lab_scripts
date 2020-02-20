#! /usr/bin/env Rscript

#' @description 
#' @author Fernando Moreno Jabato <jabato(at)uma(dot)es>
#' @import optparse, linkcomm

#############################################
### METHODS 
#############################################

suppressMessages(require(optparse))
suppressMessages(require(linkcomm))

#############################################
### CONFIGURE
#############################################
option_list <- list(
  make_option(c("-i", "--input"), type="character",
              help="Network input file"),
  make_option(c("-s", "--sep"), type="character", default = "\t",
              help="Columns file separator"),
  make_option(c("-H", "--header"), type="logical", action = "store_true", default = FALSE,
              help="Flag to be used if file has header"),
  make_option(c("-v", "--verbose"), type="logical", action = "store_true", default = FALSE,
              help="Activate verbose mode"),
  make_option(c("-o", "--output"), type="character", default = NULL,
              help="Output plain text clusters file"),
  make_option(c("-O", "--output_RDATA"), type="character",default = NULL,
              help="Output RData clusters file")
)

opt <- parse_args(OptionParser(option_list=option_list))

#############################################
### MAIN
#############################################

# Load input
if(opt$verbose) message(paste0("Loading input file: ",opt$input))
network  <- read.table(opt$input, sep = opt$sep, header = opt$header)

# Check
if(ncol(network) < 2){
  stop("Network given has less than 2 columns")
}else if(ncol(network) > 3){
  stop("Network given has more than 3 columns. Not allowed yet")
}

# Calculate clusters
if(opt$verbose){
  message("Network loaded:",opt$input)
  message(paste0("\tNodes: ",length(unique(c(network[,1],network[,2])))))
  message(paste0("\tEdges: ",nrow(network)))
  message(paste0("\tWeighted: ",ncol(network) == 3))
  message("Calculating clusters (it can take a while) ...")
} 
clustersLC <- getLinkCommunities(network, plot=FALSE, verbose = opt$verbose)

# Write output
if(!is.null(opt$output_RDATA)){
  if(opt$verbose) message(paste0("Writing output RDATA clusters object: ",opt$output_RDATA))
  save(clustersLC,file = paste0(opt$output_RDATA,".RData"))
}
if(!is.null(opt$output)){
  if(opt$verbose) message(paste0("Writing output clusters table: ",opt$output))
  write.table(clustersLC$nodeclusters, opt$nodes, sep ="\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
}

