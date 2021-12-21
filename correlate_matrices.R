#!/usr/bin/env Rscript
library(RcppCNPy)
library(optparse)


option_list <- list(
	make_option(c("-d", "--data_files"), type="character",
		help="comma-sepparated string, indicating the paths to the input files. Path patterns all also allowed"),
	make_option(c("-m", "--method"), type="character", default="pearson",
		help="Correlation method. Method available are 'pearson', 'spearman' and 'kendall'"),
	
	make_option(c("-o", "--output"), type="character", default="output",
		help="Output figure path")

)
opt <- parse_args(OptionParser(option_list=option_list))

file_list <- unlist(strsplit(opt$data_files, split=","))
if (length(file_list) == 1)
file_list <- Sys.glob(paths = file_list)

all_matrices <- lapply(file_list, npyLoad) 
names(all_matrices) <- unlist(lapply(file_list, basename))
all_matrices <- lapply(all_matrices, as.vector)
unlist(lapply(all_matrices, length))

if (length(unique(unlist(lapply(all_matrices, length)))) > 1) stop("Matrices have diferent sizes")
all_matrices <- as.data.frame(t(do.call(rbind, all_matrices)))
str(all_matrices)
output_file <- file.path(opt$output, "matrices_correlation.pdf")
pdf(output_file)
	PerformanceAnalytics::chart.Correlation(as.data.frame(all_matrices), histogram=TRUE, pch=19, log="xy", method = opt$method)
dev.off()
