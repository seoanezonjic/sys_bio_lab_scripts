#! /usr/bin/env Rscript


option_list <- list(
  optparse::make_option(c("-f", "--file"), type="character", default=NULL,
    help="File whose existence to check."),
  optparse::make_option(c("-l", "--loader_function"), type="character", default=readRDS,
    help="Function with which to load the file."),
  optparse::make_option(c("-o", "--object"), type="character", default=NULL,
    help="Object to look for in loaded workspace. Intended if checked file is
    		an R workspace (RData file).")
  )

opt <- optparse::parse_args(optparse::OptionParser(option_list=option_list))


check_output <- function(file = opt$file, loader = opt$loader_function,
						 object = opt$object) {
	if (!file.exists(file)) {
		stop(paste0("File ", file, " not found"))
	}
	loaded_file <- loader(file)
	if(is.null(object) || exists(object)) {
		return(message("Check was successful!"))
	}
	stop('File was loaded, but did not contain expected object')
}
