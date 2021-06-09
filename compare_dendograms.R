#!/usr/bin/env Rscript

option_list <- list(
  optparse::make_option(c("-d", "--dendrogram_Rdata_1"), type="character", default=NULL,
                        help="First RData file containing a single dendogram object"),
  optparse::make_option(c("-D", "--dendrogram_Rdata_2"), type="character", default=NULL,
                        help="Second RData file containing a single dendrogram object"),
  optparse::make_option(c("-o", "--output_prefix"), type="character", default="results",
                        help="Output files will be prefixed by this"),
  optparse::make_option(c("-p", "--plot_entanglement"), type="logical", default=FALSE, action = "store_true",
                        help="plot entanglement if flag present")
)
opt <- optparse::parse_args(optparse::OptionParser(option_list=option_list))

library(dendextend)
library(tidyverse)

######### IMPORT FILES AND PREPROC DATA
dend1 <- get(load(opt$dendrogram_Rdata_1))
dend2 <- get(load(opt$dendrogram_Rdata_2))
dend1_name <- tools::file_path_sans_ext(opt$dendrogram_Rdata_1)
dend2_name <- tools::file_path_sans_ext(opt$dendrogram_Rdata_2)

# Keep labels common to both dendograms
dend1_to_remove <- setdiff(labels(dend1),labels(dend2))
dend2_to_remove <- setdiff(labels(dend2),labels(dend1))
dend1 <- dendextend::prune(dend1, dend1_to_remove)
dend2 <- dendextend::prune(dend2, dend2_to_remove)

dends_list <- dendlist(dend1, dend2)
names(dends_list) <- c(dend1_name, dend2_name)


######### CALCULATE METRICS
metrics_table <- t(data.frame(
  "cor_bakers_gamma" = dendextend::cor_bakers_gamma(dends_list),
  "cor_cophenetic" = dendextend::cor_cophenetic(dends_list)
))
######### EXPORT METRICS
write.table(metrics_table, file=paste0(opt$output, '_dendrogram_correlation_metrics.txt'), sep="\t", quote=FALSE, col.names=FALSE, row.names= TRUE)

######### EXPORT TANGLEGRAM
if(opt$plot_entanglement){
  dends_list <- untangle(dends_list, method = "step2side") 
  png(paste0(opt$output, '_entanglement_plot.png'), width = 1000, height = 1000, units = "px", res=175, pointsize = 8)
    tanglegram(dends_list, common_subtrees_color_branches = TRUE)
  dev.off()
}
