#!/usr/bin/env Rscript

option_list <- list(
  optparse::make_option(c("-i", "--input_file"), type="character", default=NULL,
                        help="Input file path"),
   optparse::make_option(c("-o", "--output_file"), type="character", default=NULL,
                        help="Output PDF name without including extension '.pdf'"),
  optparse::make_option(c("-t", "--transpose"), type="logical", default=FALSE, 
                        action = "store_true", help="Use this flag to correlate rows instead columns")

)
opt <- optparse::parse_args(optparse::OptionParser(option_list=option_list))


raw_data <- read.table(opt$input_file, header=TRUE, row.names=1, sep="\t")


if (opt$transpose) {
	raw_data <- t(raw_data)
}

correlation_data <- cor(raw_data, use = "p")

clustering <- hclust(dist(correlation_data))

pdf(paste0(opt$output, ".pdf"))
	plot(clustering)
dev.off()

write.table(correlation_data, "correlation_table.txt", quote=FALSE, sep="\t")
