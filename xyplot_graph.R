#! /usr/bin/env Rscript

library(ggplot2)
library(ggExtra)
library(optparse)

################################################################
## FUNCTIONS
################################################################
ggplotRegression <- function (fit, x_axis, y_axis, distribution_type) {
	# Code from https://susanejohnston.wordpress.com/2012/08/09/a-quick-and-easy-function-to-plot-lm-results-in-r/
	g <- ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) +
	  geom_point() +
	  stat_smooth(method = "lm", col = "red") +
	  labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
	                     "Intercept =",signif(fit$coef[[1]],5 ),
	                     " Slope =",signif(fit$coef[[2]], 5),
	                     " P =",signif(summary(fit)$coef[2,4], 5))) +
	  xlab(x_axis) +
	  ylab(y_axis)
	
	ggMarginal(g, type= distribution_type, fill="transparent")
}


################################################################
## OPTPARSE
################################################################
option_list <- list(
	make_option(c("-d", "--data_file"), type="character",
		help="Tabulated file with information about each sample"),
	make_option(c("-o", "--output"), type="character", default="results",
		help="Output figure file"),
	make_option(c("-x", "--x_column"), type="character", 
		help="Name of column to be used for X dimension"),
	make_option(c("-y", "--y_column"), type="character", 
		help="Name of column to be used for Y dimension"),
	make_option(c("-D", "--distribution"), type="character", default="boxplot", 
		help="Distribution type to show in axis. 'boxplot' or 'density'")

)
opt <- parse_args(OptionParser(option_list=option_list))


################################################################
## MAIN
################################################################
data <- read.table(opt$data_file, sep="\t", header=TRUE)

pdf(paste(opt$output, '.pdf', sep=""))
	# ggplot(data, aes(x=data[[opt$x_column]], y=data[[opt$y_column]])) +
 	#  	geom_point(shape=1) +
	# 	xlab(opt$x_column) +
	# 	ylab(opt$y_column) +
	# 	geom_smooth(method=lm)
	g <- ggplotRegression(lm(data[[opt$y_column]] ~ data[[opt$x_column]], data = data),
		opt$x_column,
		opt$y_column,
		opt$distribution
	 )
	g
dev.off()
