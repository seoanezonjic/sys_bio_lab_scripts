#! /usr/bin/env Rscript


option_list <- list(
  optparse::make_option(c("-f", "--file"), type="character", default=NULL,
    help="File whose existence to check."),
  optparse::make_option(c("-l", "--loader_function"), type="character", default="readRDS",
    help="Function with which to load the file."),
  optparse::make_option(c("-o", "--object"), type="character", default=NULL,
    help="Object to look for in loaded workspace. Intended if checked file is
    		an R workspace (RData file).")
  )

opt <- optparse::parse_args(optparse::OptionParser(option_list=option_list))

loader_string <- opt$loader_function
split_string <- strsplit(loader_string, split = "::")

if(length(split_string[[1]]) == 2) {
	namespace <- split_string[[1]][1]
	func <- split_string[[1]][2]
	loader <- getFromNamespace(func, namespace)
} else {
	loader = match.fun(opt$loader_function)
}

check_output <- function(file, loader, object) {
	if (!file.exists(file)) {
		stop(paste0("File ", file, " not found"))
	}
	loaded_file <- loader(file)
	if(is.null(object) || exists(object)) {
		return(message("Check was successful!"))
	}
	stop('File was loaded, but did not contain expected object')
}

check_output(file = opt$file, loader = loader, object = opt$object)