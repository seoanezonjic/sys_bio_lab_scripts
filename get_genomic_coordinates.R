#! /usr/bin/env Rscript
#' @author James R Perkins

library(optparse)
option_list <- list(
  make_option(c("-i", "--gene_ids"), type="character", default=NULL,
    help="Single column file (list) of gene identifiers, one per line"),
  make_option(c("-t", "--gene_id_type"), type="character", default="SYMBOL",
    help="ID type for genes in input gene id list"),
  make_option(c("-o", "--output_file"), type="character", default="Genes_and_locations.txt",
    help="Output file name"),
  make_option(c("-l", "--longest"), type="character", default="",
    help="Values specifying whether the output table should show either the longest transcript found, specified in the value \"transcript\", or the largest genomic region, taken from the smallest start site to the largest end site, specified with the value \"region\".")
)
opt <- parse_args(OptionParser(option_list=option_list))

library(Homo.sapiens)

gene_ids <- scan(opt$gene_ids, "")
keytype <- opt$gene_id_type
cols <- c("SYMBOL", "GENENAME", "TXSTRAND", "TXCHROM", "TXSTART", "TXEND")
gene_locs <- select(Homo.sapiens, keys=gene_ids, columns=cols, keytype=keytype)

if(opt$longest == "transcript") {
  cat("Returning the longest annotated transcript for each gene\n")
  gene_locs_list <- lapply(unique(gene_locs$SYMBOL), function(x) { 
	gene_loc <- gene_locs[gene_locs$SYMBOL == x,]
	max_ind <- which.max(gene_loc[,"TXEND"] -  gene_loc[,"TXSTART"])
	return(gene_loc[max_ind,]) }
  )
  gene_locs <- do.call("rbind", gene_locs_list)
} else if (opt$longest == "region") {
  cat("Returning the longest possible genomic region for each gene\n")
  gene_locs_list <- lapply(unique(gene_locs$SYMBOL), function(x) {
	gene_loc <- gene_locs[gene_locs$SYMBOL == x,]
	gene_loc_return <- gene_loc[1,]
	gene_loc_return[, "TXSTART"] <- min(gene_loc[, "TXSTART"])
	gene_loc_return[, "TXEND"] <- max(gene_loc[, "TXEND"])
	return(gene_loc_return) }
  )
  gene_locs <- do.call("rbind", gene_locs_list)
} else {
  cat("No recognised value specified for the longest argument. Will potentially return  multiple transcripts for each gene\n")
}

write.table(gene_locs, file=opt$output_file,  sep="\t", quote=FALSE, row.names=FALSE)
