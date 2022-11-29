#! /usr/bin/env bash

cormit_execution_path=$1
output=$2
mkdir $output
for f in $cormit_execution_path/exec*;
do
	exec_name=`basename $f`
	exec_out_path=$output/$exec_name
	functional_out_path=$exec_out_path/functional_target
	mkdir $exec_out_path
	cp $f/miRNA_target.html $exec_out_path/
	cp $f/all_miRNA_summary.txt $exec_out_path/
	cp $f/target_results_table.txt $exec_out_path/
	mkdir $functional_out_path
	cp $f/results/*.html $functional_out_path
	cp $f/results/*.png $functional_out_path
	cp $f/results/*.csv $functional_out_path

done
