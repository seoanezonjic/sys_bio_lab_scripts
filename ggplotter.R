#!/usr/bin/env Rscript
# Sergio Alías, 20220921
# Last modified 20221019

# ggplotter.R

# Takes as input a file, selects the relevant columns,
# and then creates simple graphics using ggplot2


library(optparse)
library(matrixStats)
library(ggplot2)

############################
## Command line arguments ##
############################

option_list <- list(
  make_option(c("-i", "--input"), type = "character",
              help="Input data. It supports .tsv and .csv files"),
  make_option(c("-o", "--output"), type = "character", default = "results",
              help="Output filename, without the extension [default = %default]"),
  make_option(c("-p", "--plot"), type = "character", default = "none",
              help="Plot type. Options are:\n\t\t-> barplot\n\t\t-> boxplot\n\t\t-> violin\n\t\t-> heatmap\n\t\t-> scatterplot"),
  make_option(c("--no_header"), action = "store_true", default = FALSE,
              help="Use it if you don't have headers in the input file"),
  make_option(c("--long_format"), action = "store_true", default = FALSE,
              help="Use it if the input file is in long format (instead of the classic wide format)"),
  make_option(c("--png"), action = "store_true", default = FALSE,
              help="Use it if you wish png output instead of pdf"),
  make_option(c("-x", "--x_axis"), type = 'character', default = "all",
              help = "\r\t scatterplot:\n\t\tName or column number used for x-axis\n\t other plots:\n\t\tName(s), column number(s) or range used for x-axis [default = %default]\n\t\tExamples:\n\t\t\t-> var1,var4,var9 (no spaces between commas)\n\t\t\t-> 2,7,9\n\t\t\t-> 3:6 (3 and 6 included)"),
  make_option(c("-y", "--y_axis"), type = 'character', default = "all",
              help = "\r\t scatterplot (column):\n\t\tName or column number used for y-axis\n\t heatmap (rows):\n\t\tName(s), row number(s) or range used for y-axis [default = %default]"),
  make_option(c("-z", "--z_axis"), type = 'character', default = "no_color",
              help = "\r\t (Only for scatterplot)\n\t\t Name or column number used for coloring the points [default = no coloring]"),
  make_option(c("--error_bars"), action = "store_true", default = FALSE,
              help = "\r\t (Only for barplot)\n\t\tUse it if you wish error bars"),
  make_option(c("--show_points"), action = "store_true", default = FALSE,
              help = "\r\t (Not avaiable for heatmap or scatterplot)\n\t\tUse it if you wish individual data points"),
  make_option(c("--notch"), action = "store_true", default = FALSE,
              help = "\r\t (Only for boxplot)\n\t\tUse it if you wish notches")

)

opt <- parse_args(OptionParser(option_list = option_list))


###############
## Functions ##
###############

### Format conversion ###

#' Long format conversion
#'
#' Converts a dataframe from wide to long format
#' @param data The dataframe we want to convert
#'
#' @return Returns the dataframe in long format
#'
#' @examples
#' data <- data.frame(matrix(runif(100), nrow = 10, ncol = 10))
#' long_data <- longFormat(data)
longFormat <- function(data){
  suppressMessages(require(reshape2))
  data <- data.frame(t(data))
  data["var"] <- rownames(data)
  data <- melt(data, id.vars = "var")
  return(data)
}

#' Wide format conversion
#'
#' Converts a dataframe from long to wide format
#' @param data The dataframe we want to convert
#'
#' @return Returns the dataframe in wide format
#'
#' @examples
#' data <- data.frame(matrix(runif(100), nrow = 10, ncol = 10))
#' long_data <- longFormat(data)
#' wide_data <- wideFormat(long_data)
wideFormat <- function(data){
  suppressMessages(require(reshape2))
  names <- unique(data[, 2]) # Used later to keep row order
  data <- dcast(data, as.formula(paste0(colnames(data)[1], " ~ ", colnames(data)[2])), value.var = colnames(data)[3])
  data <- as.data.frame((t(data)))
  data$filtering <- rownames(data) # Add temporary column to filter
  data <- data[match(names, data$filtering), ] # Filter and remove possible duplicate header rows
  data$filtering <- NULL # Remove temporary filter column
  data[] <- lapply(data, function(x) {as.numeric(x)}) # Convert data to numeric since ¿dcast? converted it to character
  return(data)
}


### Input parsing ###

#' Single number checking
#'
#' Checks if a string contains a single number avaiable in data (column or row number)
#' @param n String we want to check if it is a valid column or row number
#' @param max Number of columns or rows of the data (i.e., maximun n value allowed)
#' @param arg Name of the argument we are testing
#'
#' @return Returns TRUE if the number is valid, halts execution if the number is not valid, returns FALSE if not a number
#'
#' @examples
#' data <- data.frame(matrix(runif(100), nrow = 10, ncol = 10))
#' isSingleNumber("8", ncol(data), "X_axis") # Returns TRUE
#' isSingleNumber("foo", ncol(data), "X_axis") # Returns FALSE
#' isSingleNumber("15", ncol(data), "X_axis") # Halts execution
isSingleNumber <- function(n, max, arg = "Some argument"){
  if (grepl("^[0-9]+$", n)){
    if(as.integer(n) > max || as.integer(n) <= 0){
      stop(paste0(arg, " out of bounds"))
    }
    return(TRUE)
  }
  return(FALSE)
}

#' Single name checking
#'
#'Checks if a string contains a single name avaiable in data (column or row)
#' @param n String we want to check if it is a valid column or row name
#' @param names Possible names (column or row)
#' @param arg Name of the argument we are testing
#'
#' @return Returns TRUE if the name is valid, halts execution if the name is not valid
#'
#' @examples
#' data <- data.frame(matrix(runif(100), nrow = 10, ncol = 10))
#' rownames(data) <- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j")
#' isSingleName("b", rownames(data), "Y_axis") # Returns TRUE
#' isSingleName("foo", rownames(data), "Y_axis") # Halts execution
isSingleName <- function(n, names, arg = "Some argument"){
  if(!is.element(n, names)){
    stop(paste0(arg, " name(s) not found in data"))
  }
  return(TRUE)
}

### Plot types ###

#### Barplot 

#' Barplot generator
#'
#' Plots a barplot using the arguments specyfied
#' @param data The dataframe
#' @param x Column name(s) or number(s) used for x-axis
#'
#' @return Generates the plot, which can be saved if a proper graphic device driver is started (pdf, png)
makeBarplot <- function(data, x){
  if (length(x) != 1 || x != "all"){data <- data[, x, drop = FALSE]}
  # Calculate the mean (for plotting) and the sd (for possible error bars)
  data_sum <- data.frame(t(sapply(data,
                                  function(x) c(mean = mean(x), sd = sd(x)))))
  data_sum["var"] <- rownames(data_sum) # Prepare it for ggplot
  data_sum$var <- factor(data_sum$var, levels = data_sum$var) # To keep the original variable order
  ggplot() + # I added data and aes arguments in each graphical layer
    geom_bar(data_sum,
             mapping = aes(var, mean, fill = var),
             stat = "identity",
             width = 0.5,
             color = "black") +
    labs(title = strsplit(opt$input, "\\.")[[1]][1]) + # the plot title is the filename without the file extention
    theme(plot.title = element_text(hjust = 0.5)) +
    {if(opt$show_points)geom_point(longFormat(data), # the data point layer if statement
                                   mapping = aes(var, value, fill = var),
                                   shape = 21,
                                   colour = "white",
                                   size = 2,
                                   stroke = 0.5,
                                   position = "jitter")} +
    {if(opt$error_bars)geom_errorbar(data_sum, # the error bars layer if statement
                                     mapping = aes(x = var, y = mean,
                                                   ymin = mean - sd,
                                                   ymax = mean + sd),
                                     width = .2)}
}

#### Boxplot

#' Boxplot generator
#'
#' Plots a boxplot using the arguments specyfied
#' @param data The dataframe
#' @param x Column name(s) or number(s) used for x-axis
#'
#' @return Generates the plot, which can be saved if a proper graphic device driver is started (pdf, png)
makeBoxplot <- function(data, x){
  if (length(x) != 1 || x != "all"){data <- data[, x, drop = FALSE]}
  data <- longFormat(data)
  ggplot() + # I added data and aes arguments in each graphical layer
    geom_boxplot(data,
             mapping = aes(var, value, fill = var),
             width = 0.5,
             notch = opt$notch,
             color = "black") +
    labs(title = strsplit(opt$input, "\\.")[[1]][1]) + # the plot title is the filename without the file extention
    theme(plot.title = element_text(hjust = 0.5)) +
    {if(opt$show_points)geom_point(data, # the data point layer if statement
                                   mapping = aes(var, value, fill = var),
                                   shape = 21,
                                   colour = "white",
                                   size = 2,
                                   stroke = 0.5,
                                   position = "jitter")}
}

#### Violin

#' Violin generator
#'
#' Plots a violin plot using the arguments specyfied
#' @param data The dataframe
#' @param x Column name(s) or number(s) used for x-axis
#'
#' @return Generates the plot, which can be saved if a proper graphic device driver is started (pdf, png)
makeViolin <- function(data, x){
  if (length(x) != 1 || x != "all"){data <- data[, x, drop = FALSE]}
  data <- longFormat(data)
  ggplot() + # I added data and aes arguments in each graphical layer
    geom_violin(data,
                 mapping = aes(var, value, fill = var),
                 width = 0.5,
                 color = "black") +
    labs(title = strsplit(opt$input, "\\.")[[1]][1]) + # the plot title is the filename without the file extention
    theme(plot.title = element_text(hjust = 0.5)) +
    {if(opt$show_points)geom_point(data, # the data point layer if statement
                                   mapping = aes(var, value, fill = var),
                                   shape = 21,
                                   colour = "white",
                                   size = 2,
                                   stroke = 0.5,
                                   position = "jitter")}
}

#### Heatmap

#' Heatmap generator
#'
#' Plots a heatmap using the arguments specyfied
#' @param data The dataframe
#' @param x Column name(s) or number(s) used for x-axis
#' @param y Column name(s) or number(s) used for y-axis
#'
#' @return Generates the plot, which can be saved if a proper graphic device driver is started (pdf, png)
makeHeatmap <- function(data, x, y){
  if (length(x) != 1 || x != "all"){data <- data[, x, drop = FALSE]}
  if (length(y) != 1 || y != "all"){data <- data[y, , drop = FALSE]}
  data <- longFormat(data)
  ggplot() + # I added data and aes arguments in each graphical layer
    geom_tile(data,
              mapping = aes(var, variable, fill = value)) +
    labs(title = strsplit(opt$input, "\\.")[[1]][1]) + # the plot title is the filename without the file extention
    theme(plot.title = element_text(hjust = 0.5))
}

#### Scatterplot

#' Scatterplot generator
#'
#' Plots an scatterplot using the arguments specyfied
#' @param data The dataframe
#' @param x Column name used for x-axis
#' @param y Column name used for y-axis
#' @param z Column name used for coloring the points (optional)
#'
#' @return Generates the plot, which can be saved if a proper graphic device driver is started (pdf, png)
makeScatterplot <- function(data, x, y, z = opt$z_axis){
  x <- sym(x)
  y <- sym(y)
  if (x == y){
    warning("X and Y axes are the same")
  }
  if (z != "no_color"){
    z <- sym(z)
    if (z == x || z == y){
      warning("Z-axis is the same as one of the main axes")
    }
  }
  ggplot() + # I added data and aes arguments in each graphical layer
    {if(z != "no_color")geom_point(data,
                                    mapping = aes(!!x, !!y, color = !!z))} +
    {if(z == "no_color")geom_point(data,
                                    mapping = aes(!!x, !!y))} +
    labs(title = strsplit(opt$input, "\\.")[[1]][1]) + # the plot title is the filename without the file extention
    theme(plot.title = element_text(hjust = 0.5))
}


###############
## Main code ##
###############

### Reading data ###

ext <- unlist(strsplit(opt$input, "\\."))[length(unlist(strsplit(opt$input, "\\.")))] # Getting the file extension

if (ext == "tsv"){
  sep = "\t"
} else if (ext == "csv"){
  sep = "," 
}

data <- tryCatch({
  read.table(opt$input, sep = sep, header = isFALSE(opt$no_header))},
  error = function(e) {stop("Please, use a valid input file")}
)

### Converting to wide format before the input checking (if necessary) ###

if (opt$long_format){
  data <- wideFormat(data)
}

### Input checking ###

plot_args <- "data" # This string will contain different arguments depending on the plot type

#### Check whether the plot type provided is valid

plot_options <- c("barplot", "boxplot", "violin", "heatmap", "scatterplot")

opt$plot <- tolower(opt$plot)

if(!is.element(opt$plot, plot_options)){
  stop("Please, select a valid plot type with -p or --plot. Use -h or --help for more info") # Stops execution and suggests gently to RTFM
}

#### X_axis checking

if(opt$plot == "scatterplot"){ # Must make a selection when using scatterplot
  if (opt$x_axis == "all"){ # If the option remains the default
    stop("With scatterplot you must specify the -x (--x_axis) option. Use -h or --help for more info")
  }
  else if (isSingleNumber(opt$x_axis, ncol(data), "X_axis")){ # If it is a column number
    sc_x_axis <- colnames(data)[as.integer(opt$x_axis)]
    plot_args <- paste0(plot_args, ", sc_x_axis")
  }
  else if (isSingleName(opt$x_axis, colnames(data), "X_axis")){ # If it is a column name
    sc_x_axis <- opt$x_axis
    plot_args <- paste0(plot_args, ", sc_x_axis")
  }
} else { # When other plot type is selected
  if (opt$x_axis != "all"){ # If the option is not the default
    if (grepl(",", opt$x_axis)){ # If the input is comma-separated
      indiv_cols_x <- strsplit(opt$x_axis, ",")[[1]]
      if (all(sapply(indiv_cols_x, isSingleNumber, ncol(data), "X_axis"))){
        indiv_cols_x <- colnames(data)[as.integer(indiv_cols_x)]
        plot_args <- paste0(plot_args, ", indiv_cols_x")
      }
      else if (all(sapply(indiv_cols_x, isSingleName, colnames(data), "X_axis"))){
        plot_args <- paste0(plot_args, ", indiv_cols_x")
      }
    }
    else if (grepl(":", opt$x_axis)){  # If the input is a range
      beg_end_x <- strsplit(opt$x_axis, ":")[[1]]
      if (length(beg_end_x) != 2){
        stop("Please, specify correctly the range for --x_axis")
      }
      if (all(sapply(beg_end_x, isSingleNumber, ncol(data), "X_axis"))){
        beg_end_x <- seq(beg_end_x[1], beg_end_x[2])
        beg_end_x <- colnames(data)[beg_end_x]
        plot_args <- paste0(plot_args, ", beg_end_x")
      } else {
        stop("Please, specify correctly the range for X-axis")
      }
    } else { # If it turns out to be a single number/name
      if (isSingleNumber(opt$x_axis, ncol(data), "X_axis")){
        ot_x_axis <- colnames(data)[as.integer(opt$x_axis)]
        plot_args <- paste0(plot_args, ", ot_x_axis")
      }
      else if (isSingleName(opt$x_axis, colnames(data), "X_axis")){
        ot_x_axis <- opt$x_axis
        plot_args <- paste0(plot_args, ", ot_x_axis")
      }
    }
  } else { # If the option remains the default
    default_x_axis <- opt$x_axis
    plot_args <- paste0(plot_args, ", default_x_axis")
  }
}

#### Y_axis checking for scatterplot (a column) and heatmap (a set of rows)

if (opt$plot == "scatterplot"){
  if (opt$y_axis == "all"){ # If the option remains the default
    stop("With scatterplot you must specify the -y (--y_axis) option. Use -h or --help for more info")
  }
  else if (isSingleNumber(opt$y_axis, ncol(data), "Y_axis")){ # If it is a column number
    sc_y_axis <- colnames(data)[as.integer(opt$y_axis)]
    plot_args <- paste0(plot_args, ", sc_y_axis")
  }
  else if (isSingleName(opt$y_axis, colnames(data), "Y_axis")){
    sc_y_axis <- opt$y_axis
    plot_args <- paste0(plot_args, ", sc_y_axis")
  }
} else if (opt$plot == "heatmap"){
  if (opt$y_axis != "all"){ # If the option is not the default
    if (grepl(",", opt$y_axis)){ # If the input is comma-separated
      indiv_rows_y <- strsplit(opt$y_axis, ",")[[1]]
      if (all(sapply(indiv_rows_y, isSingleNumber, nrow(data), "Y_axis"))){
        indiv_rows_y <- rownames(data)[as.integer(indiv_rows_y)]
        plot_args <- paste0(plot_args, ", indiv_rows_y")
      }
      else if (all(sapply(indiv_rows_y, isSingleName, rownames(data), "Y_axis"))){
        plot_args <- paste0(plot_args, ", indiv_rows_y")
      }
    }
    else if (grepl(":", opt$y_axis)){  # If the input is a range
      beg_end_y <- strsplit(opt$y_axis, ":")[[1]]
      if (length(beg_end_y) != 2){
        stop("Please, specify correctly the range for --y_axis")
      }
      if (all(sapply(beg_end_y, isSingleNumber, nrow(data), "Y_axis"))){
        beg_end_y <- seq(beg_end_y[1], beg_end_y[2])
        beg_end_y <- rownames(data)[beg_end_y]
        plot_args <- paste0(plot_args, ", beg_end_y")
      } else {
        stop("Please, specify correctly the range for Y-axis")
      }
    } else { # If it turns out to be a single number/name
      if (isSingleNumber(opt$y_axis, nrow(data), "Y_axis")){
        he_y_axis <- rownames(data)[as.integer(opt$y_axis)]
        plot_args <- paste0(plot_args, ", he_y_axis")
      }
      else if (isSingleName(opt$y_axis, rownames(data), "Y_axis")){
        he_y_axis <- opt$y_axis
        plot_args <- paste0(plot_args, ", he_y_axis")
      }
    }
  } else { # If the option remains the default
    default_y_axis <- opt$y_axis
    plot_args <- paste0(plot_args, ", default_y_axis")
  }
} else if (opt$y_axis != "all"){
  warning(paste0("Y_axis option will not be used for ", opt$plot))
}

#### Z-axis checking for scatterplot (if provided)

if (opt$plot == "scatterplot"){
  if (opt$z_axis != "no_color"){ # If the option is not the default
    if (isSingleNumber(opt$z_axis, ncol(data), "Z_axis")){
      sc_z_axis <- colnames(data)[as.integer(opt$z_axis)]
      plot_args <- paste0(plot_args, ", sc_z_axis")
    }
    else if (isSingleName(opt$z_axis, colnames(data), "Z_axis")){
      sc_z_axis <- opt$z_axis
      plot_args <- paste0(plot_args, ", sc_z_axis")
    }
  }
} else if (opt$z_axis != "no_color"){ # If we try to use it for a plot type that does not make sense
  warning(paste0("Z_axis option will not be used for ", opt$plot))
}

#### Other warnings

if (opt$plot != "barplot" && opt$error_bars){
  warning(paste0("The --error_bars option will be ignored for ", opt$plot))
}

if ((opt$plot == "heatmap" || opt$plot == "scatterplot") && opt$show_points){
  warning(paste0("The --show_points option will be ignored for ", opt$plot))
}

if (opt$plot != "boxplot" && opt$notch){
  warning(paste0("The --notch option will be ignored for ", opt$plot))
}

#### Output format

if(opt$png){ 
  png(paste0(opt$output, '.png'))
} else {
  pdf(paste0(opt$output, '.pdf'))
}

### Plotting ###

plot_name <- paste0(toupper(substring(opt$plot, 1, 1)), substring(opt$plot, 2)) # Make the first letter of the plot name uppercase

eval(parse(text = paste0("make", plot_name, "(", plot_args, ")"))) # Call the function for that specific plot type with its arguments

invisible(dev.off())