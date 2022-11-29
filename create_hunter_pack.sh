#! /usr/bin/env bash

path=$1
output_folder=$2
additional_path=$3
echo $path
echo $output_folder
echo $additional_path
mkdir -p $output_folder
cp $path/mapping_reports/mapping_report.html $output_folder
if [ ! -z "$additional_path" ]; then
	echo 'A'
	cp $additional_path/mapping_reports/mapping_report.html $output_folder/mapping_report_detection.html # use this to add files from other execution (miRNA DEA plus miRNA detection)
	cp $additional_path/mapping_reports/all_miRNA_report.html $output_folder/all_miRNA_report.html
	cp $additional_path/mapping_reports/miRNA_nr.fasta $output_folder/miRNA_detected.fasta
fi

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
