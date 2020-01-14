#! /usr/bin/env Rscript

#heatmap
library(gplots)
library(optparse)
 


set_option_dimension <- function (option = "both", default_value = TRUE, change_by = FALSE) {
	dimensions <- c(default_value,default_value)
	if(option == "none"){
		dimensions <- c(change_by,change_by)
	}else if(option == "column"){
		dimensions <- c(default_value,change_by)
	}else if(option == "row"){
		dimensions <- c(change_by,default_value)
	}
	dimensions
}

generate_heatmap <- function(data_matrix, clustering_dim, show_dendograms, labels){
	plot <- pheatmap::pheatmap(data_matrix, 
	cluster_cols = clustering_dim[1], 
	cluster_rows = clustering_dim[2], 
	treeheight_col = show_dendograms[1],
	treeheight_row = show_dendograms[2],
	show_colnames = labels[1],
	show_rownames = labels[2])
plot
}

transpose <- function(data_matrix){
	transpose <- t(data_matrix)
	transpose
}


################################################################
## OPTPARSE
################################################################

option_list <- list(
        make_option(c("-i", "--input_file"), type="character",
                help="Tabulated file with information about each sample"),
        make_option(c("-t", "--transpose"), default=FALSE, action="store_true", 
                help="Tabulated file with information about each sample"),
        make_option(c("-c", "--clustering"), type ="character", default="both",
        		help="Clustering columns, rows, both, or none. Possible options 'column', 'row', 'both' or 'none'. DEFAULT = %default"),
        make_option(c("-d", "--show_dendo"), type ="character", default="both",
        		help="Show column, rows, both dendograms. Possible options 'column', 'row', 'both' or 'none'. DEFAULT = %default"),
         make_option(c("-l", "--labels"), type ="character", default="both",
        		help="Show column, rows, both labels. Possible options 'column', 'row', 'both' or 'none'. DEFAULT = %default"),
        make_option(c("-o", "--output"), type="character", default="results",
                help="Output figure file"),
        make_option(c("-W", "--gwidth"), type="double", default=7,
				help="Min limit in plot"),
		make_option(c("-H", "--gheight"), type="double", default=7, 
				help="Max limit in plot")
)

opt <- parse_args(OptionParser(option_list=option_list))

################################################################
## MAIN
################################################################

data <- read.table(opt$input_file, header = TRUE , sep="\t")
data_cleaned <- data[complete.cases(data),]

data_matrix <- as.matrix(data_cleaned[,-1])
rownames(data_matrix) <- data_cleaned[,1]

clustering <- set_option_dimension(opt$clustering, default_value = TRUE, change_by = FALSE)
show_clustering <- set_option_dimension(opt$show_dendo, default_value = 50, change_by = 0)
labels <- set_option_dimension(opt$labels, default_value = TRUE, change_by = FALSE)

if(opt$transpose){
	data_matrix <- t(data_matrix)
}

pdf(paste(opt$output, '.pdf', sep=""), width=opt$gwidth , height=opt$gheight)

generate_heatmap(data_matrix = data_matrix, clustering_dim = clustering, show_dendograms = show_clustering, labels = labels)

dev.off()
