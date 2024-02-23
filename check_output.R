#! /usr/bin/env Rscript


check_output <- function(file, loader = readRDS, field = NULL) {
	if (!file.exists(file)) {
		stop(paste0("File ", file, " not found"))
	}
	loaded_file <- loader(file)
	if (!is.null(field)) {
		check <- loaded_file$field
	}
	message("Check was successful!")
}
