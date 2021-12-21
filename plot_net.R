#!/usr/bin/env Rscript

library(igraph)
args <- commandArgs(trailingOnly = TRUE)

net_data <- read.table(file.path(args[1]), header = FALSE)
colnames(net_data) <- c("from","to","weight")
net_processed <- graph_from_data_frame(net_data, directed = FALSE)
E(net_processed)$weight <- net_data$weight  
is_weighted(net_processed)

pdf("net.pdf")

plot(net_processed, layout=layout_with_kk, vertex.label = NA, vertex.size = 1)

dev.off()
