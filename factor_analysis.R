#! /usr/bin/env Rscript

library(optparse)
library(FactoMineR)
library("corrplot")
library(factoextra)
library(cluster)
#library(RANN)
library(fmsb)
suppressMessages(library(PerformanceAnalytics))
library(FactoInvestigate)

################################################################
# OPTPARSE
################################################################
option_list <- list(
	make_option(c("-m", "--clustering_method"), type="character", default="ward", 
		help="Clustering method to use on HCPC function: "),
	make_option(c("-d", "--data_file"), type="character", 
		help="Tabulated file with information about each sample"),
	make_option(c("-c", "--columns_data"), type="character", 
		help="Columns data to use in PCA analysis"),
	make_option(c("-t", "--quantitative_column_values"), type="character", default="c()",
		help="Number of column with quantitative values to be analyzed"),
	make_option(c("-l", "--qualitative_column_values"), type="character", default="c()", 
		help="Number of column with qualitative values to be analyzed"), 
	make_option(c("-r", "--references"), type="character", default="", 
		help="Set the points to use as reference an calculate the closer points"), 
	make_option(c("-g", "--group_colors"), type="character", default="", 
		help="Colorize pca points using the labels of the given column name"), 
	make_option(c("-k", "--keep_dimensions"), type="integer", default=3, 
		help="Number of dimensions to keep for analysis"),
        make_option(c("-C", "--clusters"), type="integer", default=-1,
                help="Number of clusters to search on PCA data, by default is automatic"),
	make_option(c("-o", "--output"), type="character", default='./PCA_graphic_results', 
		help="Output path for pdf results"),
	make_option(c("-I", "--no_investigate"), action="store_true", default=FALSE, 
		help="Do not perform factominer Investigate function. Use when there are reference samples in PCA data. Default FALSE"),
	make_option(c("-u", "--use_header"), action="store_false", default=TRUE, 
		help="Use first line as header. Default true")

)
opt <- parse_args(OptionParser(option_list=option_list))

################################################################
## MAIN
################################################################

data_table <- read.table(opt$data_file, sep="\t", header=opt$use_header, row.names=1)
data_positions_for_PCA <- eval(parse(text=paste('c(', opt$columns_data, ')')))
print(data_positions_for_PCA)
quantitative_data_positions <- eval(parse(text=paste('c(', opt$quantitative_column_values, ')')))
qualitative_data_positions <- eval(parse(text=paste('c(', opt$qualitative_column_values, ')')))
active_data <- data_table[ , data_positions_for_PCA]
active_data <- active_data[, colSums(active_data != 0) > 0] # Remove zero columns
data_positions_for_PCA <- names(active_data) #remove user cols that are zeros
correlations <- round(cor(active_data),2) 
correlations[is.na(correlations)] <- 0
write.table(correlations, file = file.path(dirname(opt$output), "correlation_matrix.txt"), sep = "\t")

cols_data_table <- length(data_positions_for_PCA)
data_positions_for_PCA <- c(data_positions_for_PCA, quantitative_data_positions, qualitative_data_positions)
data_table <- data_table[ , data_positions_for_PCA]

references <- NULL
row_refs <- NULL
if(opt$references != '' ){
        references <- unlist(strsplit(opt$references, ','))
        row_refs <- which(row.names(data_table) %in% references)
}

if(class(quantitative_data_positions) == 'character'){
	quantitative_data_positions <- match(quantitative_data_positions, colnames(data_table))
}else{
	if(length(quantitative_data_positions)){
		quantitative_data_positions <- c(1:length(quantitative_data_positions)) + cols_data_table
	}
}

if(class(qualitative_data_positions) == 'character'){
	qualitative_data_positions <- match(qualitative_data_positions, colnames(data_table))
}else{
	if(length(qualitative_data_positions)){
		qualitative_data_positions <- c(1:length(qualitative_data_positions)) + cols_data_table + length(quantitative_data_positions)
	}
}
# Check if factor columns have more than 1 category
valid_positions <- c()
correction_factor <- 0
for(i in qualitative_data_positions){
	index <- i - correction_factor
	factor_col <- factor(data_table[ , index])
	data_table[ , index] <- factor_col
	if(!is.null(row_refs)){
		factor_col <- factor_col[-row_refs]
		factor_col <- droplevels(factor_col)
	}
	if(nlevels(factor_col) > 1){
		valid_positions <- c(index, valid_positions)
	}else{
		warning(paste("The column ", names(data_table)[i]), " has a single category. It will be removed.")
		data_table <- data_table[ , -index]
		correction_factor <- correction_factor + 1
	}
}
qualitative_data_positions <- valid_positions
### PCA ###
res.pca <- PCA(data_table, ncp=opt$keep_dimensions, scale.unit=TRUE, quanti.sup=quantitative_data_positions, quali.sup=qualitative_data_positions, graph=FALSE, ind.sup=row_refs)

#Prepare data for add supp individuals to hcpc (code patch, factominer is unable to do this feature)
pca_for_hcpc <- PCA(data_table, ncp=opt$keep_dimensions, scale.unit=TRUE, quanti.sup=quantitative_data_positions, quali.sup=qualitative_data_positions, graph=FALSE, ind.sup=row_refs)
if(!is.null(references)){
	join <- rbind(pca_for_hcpc$ind$coord, pca_for_hcpc$ind.sup$coord) #join suplemental individuals to show on hcpc
	join <- join[ order(row.names(join)), ] # reorder to make coord order consistent with X data
	pca_for_hcpc$ind$coord <- join
	pca_for_hcpc$call$X <- pca_for_hcpc$call$X[ order(row.names(pca_for_hcpc$call$X)), ]  # reorder to make X order consistent with coord data
	pca_for_hcpc$call$row.w.init <- rep(1,nrow(pca_for_hcpc$ind$coord))
	fill_val <- max(pca_for_hcpc$call$row.w)
	pca_for_hcpc$call$row.w <- c(pca_for_hcpc$call$row.w, rep(fill_val, length(row_refs)))
	pca_for_hcpc$call$ind.sup <- NULL
}

if(!opt$no_investigate){
	Investigate(res.pca)
}

res.hcpc <- HCPC(pca_for_hcpc, nb.clust=opt$clusters, graph=FALSE, method=opt$clustering_method)#, iter.max = 20, min = 5)
closest <- NULL

if(!is.null(references)){
	## Calculate matrix distance as factominer's HCPC functios does it.
	X = as.data.frame(pca_for_hcpc$ind$coord)
	do <- dist(X, method = "euclidian")^2
	weight <- pca_for_hcpc$call$row.w.init # By default this attribute is to 1 on Factominer
	eff <- outer(weight, weight, FUN = function(x, y, n) {
		x * y/n/(x + y)
		}, n = sum(weight))
	dissi <- do * eff[lower.tri(eff)] # final object which function flash:hclust receives on Factominer
	mat <- as.matrix(dissi)
	
	# Calculate average distances of each individual to the references
	references <- unlist(strsplit(opt$references, ','))

	reference_distances <- rep(0, times=nrow(mat) - length(references))
	count = 0
	for(i in references){
		current_ref_dist <- mat[i, ] # get distances to a given refererence
		no_references <- current_ref_dist[!names(current_ref_dist) %in% references] #remove distance to reference samples
		reference_distances <- reference_distances + no_references
		count = count + 1 
	}
	average_distances <- sort(reference_distances/count)
        cat("############### INDIVIDUALS RANKING ################\n")
	distances <- data.frame(average_distances)
        print.data.frame(distances)

	
	#stop()
	## EUCLIDIAN
	#reference_points_x = res.pca$ind$coord[references, "Dim.1"]
	#reference_points_y = res.pca$ind$coord[references, "Dim.2"]
	#centroid_x <- mean(reference_points_x)
	#centroid_y <- mean(reference_points_y)
	#all_points <- data.frame(cbind(x=res.pca$ind$coord[,"Dim.1"], y=res.pca$ind$coord[,"Dim.2"]))
	#reference_point <- data.frame(cbind(x=centroid_x, y=centroid_y))
	#closest <- nn2(all_points[, 1:2], query = reference_point, k = length(res.pca$ind$coord[,"Dim.1"]))
	#names <- names(res.pca$ind$coord[ ,"Dim.1"])[closest$nn.idx]
	#distances <- as.vector(closest$nn.dist)
	#max <- max(closest$nn.dist)
	#percentage <- distances/max*100
	#distances <- data.frame(distances, percentage)
	#row.names(distances) <- names
	#cat("############### INDIVIDUALS RANKING ################\n")
	#print.data.frame(distances)
}

# prepare data for radar plot

test <- active_data
MX <- sapply(test, function(x) max(x) )
MN <- sapply(test, function(x) min(x) )
test <- rbind(MX, MN, test)

COL<-colorRampPalette(c("red", "blue", "green", "orange"))(nrow(test)-2)

options("width"=200) #Print on screen 200 character columns instead of 80
cat("\n############### HCPC CLUSTERS ################\n")
print(res.hcpc$call$X)

cat("\n############### PCA DESCRIPTION ################\n")
print(dimdesc(res.pca, axes=c(1,2)))

# See http://www.sthda.com/english/wiki/factominer-and-factoextra-principal-component-analysis-visualization-r-software-and-data-mining
pdf(file= paste(opt$output, '.pdf', sep=''), width=10, height = 10)
	radarchart(test, pcol=COL)
	legend("topleft", legend=rownames(test)[-c(1,2)], col=COL, pch = 16, lty = 1)
	corrplot(correlations, type="upper", order="hclust",
        	tl.col="black", tl.srt=45, title = "Correlation matrix with active variables")
        corrplot(correlations, type="upper", order="hclust",
        	tl.col="black", tl.srt=45, title = "Correlation matrix with active variables", addCoef.col = TRUE, addCoefasPercent = TRUE)
	chart.Correlation(active_data, histogram=TRUE, pch=19)
	plot(hclust(as.dist(1 - abs(correlations/100))))
	plot.PCA(res.pca, axes=c(1, 2), choix="ind")
	plot.PCA(res.pca, axes=c(1, 2), choix="ind", label = "none")
	if(opt$group_colors != ""){
		colors = c("green", "blue", "red", "yellow", 'pink', 'black')
		plot(res.pca, habillage = opt$group_colors, col.hab = colors, label=c('ind'))
	}
	fviz_pca_ind(res.pca, col.ind="cos2") +
		scale_color_gradient2(low="white", mid="blue", high="red", midpoint=0.50)
	#plot.PCA(res.pca, axes=c(1, 2), choix="var")
	fviz_pca_var(res.pca, col.var="steelblue") +
		theme_minimal()
	fviz_pca_var(res.pca, alpha.var="contrib")+
		theme_minimal()
	plot(res.hcpc , axes=c(1,2), choice="tree")
	plot(res.hcpc , axes=c(1,2), choice="map", draw.tree= FALSE)
	plot(res.hcpc , axes=c(1,2), choice="map", draw.tree= FALSE, label="none")
	plot(res.hcpc , axes=c(1,2), choice="map")
	plot(res.hcpc , axes=c(1,2), choice="3D.map")
dev.off()

