#!/usr/bin/env Rscript

option_list <- list(
  optparse::make_option(c("-i", "--input_file"), type="character", default=NULL,
                        help="tab separated, 3 columns, first two represent the pair, third represents the weight"),
  optparse::make_option(c("-k", "--cluster_number"), type="integer", default=2,
                        help="number of processes for parallel execution"),
  optparse::make_option(c("-o", "--output_path"), type="character", default="results",
                        help="Define the output folder, where 1 file per cluster will be added, containing all pairs from the input file that were found in that cluster. A final file will be produced containing all pairs in the original file that were not found in the same cluster "),
  optparse::make_option(c("-p", "--plot_dendogram"), type="logical", default=FALSE, action = "store_true",
                        help="plot a cluster dendogram if flag present")

)
opt <- optparse::parse_args(optparse::OptionParser(option_list=option_list))

library(optparse)
library(igraph)
library(fastcluster)
dir.create(opt$output_path)
output_path <- normalizePath(opt$output_path)

edge_list <- read.table(opt$input_file, header=FALSE)

# Convert using base R as igraph takes foreeeever
unique_elements <- unique(c(edge_list[,1], edge_list[,2]))
n_elements <- length(unique_elements)
adj_matrix<-matrix(0, n_elements, n_elements)
row.names(adj_matrix) <- colnames(adj_matrix) <- unique_elements
adj_matrix[as.matrix(edge_list)[,1:2]] <- edge_list[,3]
adj_matrix[as.matrix(edge_list)[,2:1]] <- edge_list[,3]

# Perform clustering
dist_matrix <- as.dist(max(adj_matrix) - adj_matrix)
hc <- fastcluster::hclust(dist_matrix, method="ward.D")
clust_membership <- cutree(hc, k = opt$cluster_number)


# Generate output
if(opt$plot_dendogram){
  png(file.path(output_path, "hclust_dendogram.png"))
  plot(hc)
  dev.off()
}
clusters_and_members <- lapply(unique(clust_membership), function(x) {
  cluster_members <- names(clust_membership)[clust_membership == x]
  combn(cluster_members, 2)
  # Obtain original pairs and weights for pairs where both members are in this cluster
  cluster_edge_list <- edge_list[edge_list[,1] %in% cluster_members & edge_list[,2] %in% cluster_members, ]
  utils::write.table(cluster_edge_list,
                     file=file.path(output_path, paste0("pairs_in_cluster_", x ,".txt")),
                       quote=FALSE, col.names=TRUE, row.names = FALSE, sep="\t")
  cluster_edge_list
})

# Obtain the pairs that were not found in the same cluster using a set diff
clusters_and_members <- data.table::rbindlist(clusters_and_members)
no_cluster_pairs <- data.table::setDT(edge_list)[!clusters_and_members, on = names(edge_list)]

utils::write.table(no_cluster_pairs,
                   file=file.path(output_path, "no_cluster_pairs.txt"),
                     quote=FALSE, col.names=TRUE, row.names = FALSE, sep="\t")

