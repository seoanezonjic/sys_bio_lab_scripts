#! /usr/bin/env bash

path=$1
output_folder=$2
mkdir -p $output_folder
cp $path/mapping_reports/mapping_report.html $output_folder

for comparison_path in $path/DEGenesHunter_results/*
do
    out_comparison="$output_folder/$(basename "$comparison_path")"
    mkdir -p $out_comparison
    cp $comparison_path/DEG_report.html $out_comparison
    cp $comparison_path/filtered_count_data.txt $out_comparison
    cp $comparison_path/final_counts.txt $out_comparison
    cp $comparison_path/control_treatment.txt $out_comparison
    cp -r $comparison_path/Common_results $out_comparison
    cp -r $comparison_path/functional_enrichment $out_comparison
    cp -r $comparison_path/Results_WGCNA $out_comparison
    rm -rf $out_comparison/Results_WGCNA/*.RData
done
