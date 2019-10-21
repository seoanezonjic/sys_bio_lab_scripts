#! /usr/bin/env Rscript

library(optparse)

########################################################################
## FUNCTIONS
########################################################################
load_event_data <- function(file, col_id, col_event, header){
	data <- read.table(file, header=header, stringsAsFactors=FALSE, sep="\t", quote= "")
        split_events <- strsplit(data[,col_event], ",")
	ids <- data[, col_id]
        event_data <- lapply(unique(ids), function(id)
                unique(unlist(split_events[ids == id]))
        )
        names(event_data) <- unique(ids)
        all_events <- unlist(event_data)
        event_attr <- list('event_data' = event_data, 'total' = length(unique(all_events)))
        return(event_attr)
}

load_relations <- function(file){
	relations <- read.table(file, header=FALSE, stringsAsFactors=FALSE, sep="\t")
	return(relations)
}
########################################################################
## OPTPARSE
########################################################################

option_list <- list(
  make_option(c("-d", "--data"), type="character",
              help="Path to file with event data"),
  make_option(c("-r", "--relations"), type="character",
              help="Path to tabulated file with pairs to calculate significance"),
  make_option(c("-H","--header"), type="logical", default=FALSE,
              help="If data file has headers. Default, false"),
  make_option(c("-i","--col_id"), type = "character",
              help="Column name in which perform comparations"),
  make_option(c("-e","--col_event"), type = "character", 
              help="Column name with comma separated ocurrence events")
)

opt <- parse_args(OptionParser(option_list=option_list))

########################################################################
## MAIN
########################################################################
event_attr <- load_event_data(opt$data, opt$col_id, opt$col_event, opt$header)
event_data <- event_attr[['event_data']]
event_total <- event_attr[['total']]
relations <- load_relations(opt$relations)
for(row in 1:nrow(relations)){
	pair <- relations[row, ]
	a_events <- event_data[[pair[, 1]]]
	b_events <- event_data[[pair[, 2]]]
	if(!is.null(a_events) && !is.null(b_events)){
		a_number <- length(a_events)
		b_number <- length(b_events)
		intersection <- length(intersect(a_events, b_events))
		pval <- phyper(intersection-1, a_number, event_total-a_number, b_number, lower.tail=FALSE) # SITO's way
		cat(pair[, 1], pair[, 2], pval, "\n",  sep="\t")
		#union_pair <- length(union(a_number, b_number))
		#contigence_table <- matrix(
		#	c(intersection, b_number - intersection, a_number - intersection, event_total - union_pair), 
		#	dimnames = list(c("Intersection", "B specific"), c("A specific", "Neither both")),
		#	nrow = 2 
		#)
		#pval <- fisher.test(contigence_table, alternative='greater')[['p.value']] # Fisher exact test way
		#print(pval)
	}else{
		warning(paste('Data not found for pair:', pair[, 1], pair[, 2] , sep= ' '))
	}
}
