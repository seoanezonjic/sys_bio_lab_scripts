#! /usr/bin/env Rscript

library(optparse)
library(RcppCNPy)


get_group_submatrix_mean <- function(group, matrix_transf, groups=groups) {
  mean(matrix_transf[
		names(groups)[groups %in% group],
		names(groups)[groups %in% group]
      ], na.rm=TRUE
  )
}

calc_sim_within_groups <- function(matrix_transf, groups) {
	unique_groups <- unique(groups)
	group_mean_sim <- sapply(unique_groups, get_group_submatrix_mean, matrix_transf=matrix_transf, groups=groups)
	names(group_mean_sim) <- unique_groups
	group_mean_sim
}


option_list <- list(
	make_option(c("-d", "--data_file"), type="character",
		help="Tabulated file with information about each sample"),
	make_option(c("-y", "--npy"), type="character", default=NULL,
		help="Indicates that input file is a numpy matrix and the given PATH is a file with axis labels"),
	make_option(c("-g", "--groups"), type="character", default=NULL,
		help="File indicating which patient is in which group"),
	make_option(c("-o", "--output"), type="character", default="output",
		help="Output prefix")
)
opt <- parse_args(OptionParser(option_list=option_list))

axis_labels <- read.table(opt$npy, header=FALSE, stringsAsFactors=FALSE)
data <- npyLoad(opt$data_file)
colnames(data) <- axis_labels$V1
rownames(data) <- axis_labels$V1
diag(data) <- NA


groups <- read.table(opt$groups, header=FALSE)

groups_vec <- groups[,2]
names(groups_vec) <- groups[,1]

sim_within_groups <- calc_sim_within_groups(data, groups_vec)
write.table(sim_within_groups, file=paste0(opt$output, '_group_sims.txt'), sep="\t", quote=FALSE, col.names=FALSE, row.names= TRUE)

