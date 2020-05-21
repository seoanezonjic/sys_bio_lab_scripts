#! /usr/bin/env Rscript
#' @author James R Perkins

library(optparse)
option_list <- list(
  make_option(c("-i", "--gene_ids"), type="character", default=NULL,
    help="Single column file (list) of gene identifiers, one per line"),
  make_option(c("-g", "--gene_id_type"), type="character", default="ENTREZID",
    help="ID type for genes in input gene id list. For a list of all allowed IDs please run this script with the -k option"),
  make_option(c("-t", "--converted_id_type"), type="character", default="SYMBOL",
    help="ID type you wish to translate to. To output more than one ID type, please separate with commas. For a list of all allowed IDs please run this script with the -k option"),
  make_option(c("-o", "--output_file"), type="character", default=NULL,
    help="Output file name. If NULL, will write to standard output."),
  make_option(c("-s", "--organism_db"), type="character", default="org.Hs.eg.db",
    help="Organism db file to use for the conversion, normally of format org.XX.eg.db"),
  make_option(c("-k", "--list_keytypes"), type="logical", default=FALSE,
   help="View allowed keys to be used to convert the gene IDs from and to. May include other annotation types that are not strictly gene IDs."),
  make_option(c("-d", "--list_available_databases"), type="logical", default=FALSE,
   help="List libraries with the extension .db installed in this version of R")
)
opt <- parse_args(OptionParser(option_list=option_list))

library(opt$organism_db, character.only=TRUE)
org.db <- eval(parse(text=opt$organism_db))

if(opt$list_keytypes == TRUE || opt$list_available_databases == TRUE) {
  if(opt$list_keytypes == TRUE) {
    print("All available keytypes for performing translations. Please rerun without the list_keytypes (-k) option to produce output:")
    print(columns(org.db))
  }
  if(opt$list_available_databases == TRUE) {
    print("All installed databases. Please rerun without the list_available_databases  (-d) option to produce output:")
    packs <- installed.packages()
    print(grep(".db", row.names(packs), value = TRUE))
  }
  q()
}

if(is.null(opt$gene_ids)){
  stop("No input list of gene ids given.")
}
gene_ids <- readLines(opt$gene_ids)

converted_id_type <- unlist(strsplit(opt$converted_id_type, ","))

translation_table <- select(x=org.db, keys=gene_ids, keytype=opt$gene_id_type, columns=converted_id_type)
translation_table <- unique(translation_table)
# Write to standard out unless a table of translations is given
if(is.null(opt$output_file)) {
  write.table(translation_table, row.names=FALSE, quote=FALSE, sep="\t", col.names=FALSE)
} else {
  write.table(translation_table, file=opt$output_file, row.names=FALSE, quote=FALSE, sep="\t", col.names=FALSE)
}
