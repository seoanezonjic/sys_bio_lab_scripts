#!/usr/bin/env Rscript
 

library(optparse)

# extrac

################################################################
## OPTPARSE
################################################################

option_list <- list(
	make_option(c("-i", "--input_file"), type="character",
		help="Tabulated file with 3 columns (sample, value and group)"),
	make_option(c("-s", "--sample_column"), type="integer", default=1,
        help="Name or index of sample column. Sample names must be unique. Default = %default"),
	make_option(c("-v", "--value_column"), type="integer", default=2,
        help="Name or index of calue column. Default = %default"),
	make_option(c("-g", "--group_column"), type="integer", default=3,
        help="Name or index of group column. Default = %default"),
	make_option(c("-H", "--header"), type="logical", action = "store_true", default = FALSE, 
		help="Use this option to indicate column names"),
	make_option(c("-t", "--test_type"), type="character", default = "",
		help="Indicate test type. t_test: you must to indicate 't_test' and hypothesis separated by ':' (grater, two.sided or less)."),
	make_option(c("-o", "--output"), type="character", 
		help="Output path")
)

opt <- parse_args(OptionParser(option_list=option_list))

################################################################
## MAIN
################################################################
raw_table <- read.table(opt$input_file, header = opt$header , sep="\t")

opt$test_type  <- unlist(strsplit(opt$test_type ,":"))
if (opt$test_type[1] == "t_test"){
	
	parsed_table <- raw_table[,c(opt$value, opt$group)]

	# rownames(parsed_table) <- 
	# raw_table[,opt$sample]
	v_col <- 1 #parsed value column index
	g_col <- 2 #parsed group column index

	# By now can manage 2 proups input only
	groups <- unique(parsed_table[,g_col])
	if (length(groups) == 1) {
		cat("NONE", fill = TRUE)
		q()
	}
	ref_values <- parsed_table[parsed_table[,g_col] == groups[1], v_col]
	sub_values <- parsed_table[parsed_table[,g_col] == groups[2], v_col]

	if (length(ref_values) < 2 ||length(sub_values) < 2) {
		cat("NONE", fill = TRUE)
	} else {
		t_test_result <- t.test(x = ref_values, y = sub_values,
		       alternative = opt$test_type[2],
		       mu = 0, paired = FALSE, var.equal = FALSE,
		       conf.level = 0.95)
		cat(t_test_result$p.value, fill = TRUE)
	}



}
