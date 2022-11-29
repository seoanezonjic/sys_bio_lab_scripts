#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

counts_table <- read.table(args[1])
reads_sum <- colSums(counts_table)
cat(names(reads_sum))
cat("\n")
cat(reads_sum)
cat("\n")
