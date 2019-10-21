#! /usr/bin/env Rscript



#' Method used to load a table from a file and remove not complete entries
#'
#' @param file to be loaded
#' @param sep separator used into file
#' @param quote character used as quotes into file
#' @param header used to indicate if file has a header or not
#' @param strirngsAsFactors used to indicate if strings must be stored as factors or not
#' @param comment.char character used as comment flag into file
#' @param complete if TRUE, only complete cases will be returned
#' @return the laoded and filtered data contained into given file
#' @author refactored by Fernando Moreno Jabato \email{fmjabato@@gmail.com}. Original author Pedro Seoane Zonjic
get_data <- function(file, sep = "\t", quote = "", header = TRUE, stringsAsFactors = TRUE, comment.char = "", complete = TRUE){
    # Load raw data
    raw <- read.table(file   = file, 
                      sep    = sep,
                      header = header, 
                      comment.char = comment.char, 
                      stringsAsFactors = stringsAsFactors)

    # Check complete cases
    if(complete){
        return(raw[complete.cases(raw),])
    }

    # Return loaded data
    return(raw)
}



#' Calculate the best threeshold for a given performance and write it as a text in the output channel
#' 
#' @param perf performance object from ROCR package
#' @author Pedro Seoane Zonjic
get_best_thresold <- function(perf){
    accuracy <- unlist(slot(perf, "y.values"))
    thresolds <- unlist(slot(perf, "x.values"))
    max_ac <- max(accuracy)
    best_thresold <- max(thresolds[which(accuracy %in% max_ac)])
    print(best_thresold)
}




#' Generate ROC curves from a dataframe given and render it out into a file
#'
#' @param file file with predictions and success values
#' @param tags Success values column indexes (number and/or numeric values)
#' @param series Prediction column indexes (number and/or numeric values)
#' @param graphname output file basename (extension is added automatically)
#' @param method graph type. Allowed: 'ROC' and 'prec_rec'
#' @param xlimit graph X-axis limits
#' @param ylimit graph Y-axis limits
#' @param format output format. Allowed: 'pdf','png'
#' @param label_order Prediction column names
#' @param compact_graph if TRUE, all lines will be plotted in the same graph
#' @param legend show, or not, the legend
#' @param cutOff if TRUE, cutoff curves are plotted and RATE measure is used
#' @param rate measure to plot. ONLY USED when cutOff is true
#' @importFrom ROCR prediction performance
#' @author refactored by Fernando Moreno Jabato \email{fmjabato@@gmail.com}. Original author Pedro Seoane Zonjic
drawing_ROC_curves <- function(file, tags, series, graphname, method, xlimit, ylimit, format, label_order,compact_graph = TRUE, legend = TRUE, cutOff = FALSE, rate){
    # Load necessary packages
    require(ROCR)

    # Prepare plots values to be calculated
	if(method == 'ROC'){
		x_axis_measure="fpr"
		y_axis_measure="tpr"
        legend_position="bottomright"
	}
	else if(method == 'prec_rec'){
		x_axis_measure="rec"
		y_axis_measure="prec"
        legend_position="topright"
	}else if(method == 'cut'){
        legend_position="bottomleft"
    }else{
        stop(paste("Method not allowed: ", method, sep = ""))        
    }

    # Prepare output graphs
    if(format=='pdf'){
	    pdf(paste(graphname,".pdf", sep = ""))
    }else if(format=='png'){
	    png(paste(graphname,".png", sep = ""))
    }else{
        stop("Export format not allowed")
    }

    # Prepare plot data
	colors <- c('red', 'blue', 'green', 'orange', 'black', 'magenta', 'yellow', 'cyan', 'darkgray')
  
    # Prepare legend container
    legend_tag <- c()

    for(i in seq_along(file)){
        # Load file
        table <- get_data(file[i])
        # Obtain prediction values
        tag <- if(length(tags)>1) tags[[i]] else{tags[[1]]}
        hits <- table[,tag]
        serie <- table[,series[[i]]]

        # Create a prediction object
        pred <- prediction(serie, hits, label_order)
        if(cutOff){ # Plot cutoff curves
            perf <- performance(pred, measure = rate)
            get_best_thresold(perf)
        }else{
            perf <- performance(pred, measure = y_axis_measure, x.measure =  x_axis_measure)
        }

        # Plot info
        plot(perf, add=(compact_graph & (i>1)), col=colors[i], xlim=xlimit, ylim=ylimit)

        # Prepare legend
        if(method == 'ROC'){
            AUC <- performance(pred, measure = "auc")
            AUC <- unlist(slot(AUC, 'y.values'))
            legend_tag <- c(legend_tag, paste(series[[i]], '=', round(AUC, 3), sep=' '))
        }else{
            legend_tag <- c(legend_tag, series[[i]])
        }
    } # END i FOR

    # Add legend and render final image
    if(legend){
        legend(legend_position, legend=legend_tag, col=colors, lwd=2)                      
    }
    dev.off()    
}