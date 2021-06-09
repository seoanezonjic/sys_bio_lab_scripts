#!/usr/bin/env bash
#script for download multimir database on Picasso or another cluster with cpu limit in login 
#download_multimir.sh path/to/output comma,separated,organisms

output_path=$1 #
all_organisms=$2 #comma separated organism keys (hsa, mmu)
source ~soft_bio_267/initializes/init_degenes_hunter
export PATH=~josecordoba/software/DEgenesHunter/inst/scripts:$PATH
mkdir $output_path
for organism in `echo $all_organisms | tr "," " "`; do
	check_file=$output_path/`echo $organism`_finished
	rm -r $output_path/`echo $organism`_multimir_err
	while [ ! -s $check_file ]; do
		download_multiMiR.R -s 50 -O $organism -o $output_path -c &>> $output_path/`echo $organism`_multimir_err
	done
	rm -r $check_file
done
