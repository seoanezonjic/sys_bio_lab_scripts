#! /usr/bin/env Rscript


check_output <- function(file, loader = readRDS, object = NULL) {
	if (!file.exists(file)) {
		stop(paste0("File ", file, " not found"))
	}
	loaded_file <- loader(file)
	if(is.null(object) || exists(object)) {
		return(message("Check was successful!"))
	}
	stop('File was loaded, but did not contain expected object')
}
