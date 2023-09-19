#! /usr/bin/env bash

cormit_path=$1/coRmiT.R_0000/results
target_fun=$1/clusters_to_enrichment.R_0000/DB_functional
output_cormit=$2/miRNA_target_results
output_func=$2/target_functional_results
mkdir -p $output_cormit
mkdir -p $output_func

cp $cormit_path/miRNA_target.html $cormit_path/target_results_table.txt $cormit_path/hunter_results_table_translated.txt $output_cormit/

cp $target_fun/*html $target_fun/*csv $output_func/
