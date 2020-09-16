#!/usr/bin/env bash
#script for download multimir database on Picasso or another cluster with cpu limit in login 
#download_multimir.sh path/to/output comma,separated,organisms

output_path=$1 #
all_organisms=$2 #comma separated organism keys (hsa, mmu)
source ~soft_bio_267/initializes/init_degenes_hunter
#export PATH=~josecordoba/software/DEgenesHunter/:$PATH
mkdir $output_path
if [ -s $output_path/finished ]; then
	rm $output_path/finished
fi
for organism in `echo $all_organisms | tr "," " "`; do
	while [ ! -s $output_path/finished ]; do
		download_multiMiR.R -s 50 -O $organism -o $output_path -c #&> $output_path/multimir_log
	done
	rm -r $output_path/finished
done
