#! /usr/bin/env Rscript

library(ggplot2)
library(optparse)

#####################
## OPTPARSE
#####################
option_list <- list(
        make_option(c("-d", "--data_file"), type="character",
                help="Tabulated file with information about each sample"),
        make_option(c("-o", "--output"), type="character", default="out",
                help="Output figure file"),
        make_option(c("-H", "--header"), action="store_false", default=TRUE,
        	help="The input table not have header line"),
        make_option(c("-x", "--x_values"), type="character", 
		help="Name of column X with values to be plotted"),
        make_option(c("-s", "--series"), type="character", default = NA, 
		help="Name of column X with values of the series"),
	make_option(c("-X", "--x_lab"), type="character", default="",
        	help="Use for set x axis lab"),
	make_option(c("-l","--legend"), type="character", default="",
        	help="Use for set legend name"),
	make_option(c("--x_max"), type="integer", default=NA,
        	help="Use for set x axis legend"),
	make_option(c("--x_min"), type="integer", default=NA,
        	help="Use for set x axis legend"),
	make_option(c("--alpha"), type="double", default=0.5,
        	help="Set transparency")
	)
opt <- parse_args(OptionParser(option_list=option_list))

#####################
## MAIN
#####################
data <- read.table(opt$data_file, header=opt$header, sep="\t")
if (opt$header == FALSE) colnames(data) <- as.character(seq(1,ncol(data))) 

if (!is.null(opt$series)) {
	obj <- ggplot(data, aes(x=data[,opt$x_values], fill = as.factor(data[,opt$series])))
} else {
	obj <- ggplot(data, aes(x=.data[,opt$x_values]))
}


obj <- obj + geom_density()
obj <- obj + xlab(opt$x_lab)
obj <- obj + xlim(opt$x_min, opt$x_max) 
obj <- obj + guides(fill=guide_legend(title=opt$legend))

pdf(paste(opt$output, '.pdf', sep=""))
	obj
dev.off()
