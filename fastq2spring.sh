#!/usr/bin/env bash
#SBATCH --cpus-per-task=16
#SBATCH --mem='100gb'
#SBATCH --time='1-10:00:00'
#SBATCH --constraint=cal
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out

# Description: Script to compress FASTQ files to SPRING
# Works with single and paired reads.
# Please provide as input arguments:
# 1. Input folder
# 2. Output folder
# 3. File with filenames to convert from FASTQ to SPRING
# 4. Please choose layout: single or paired
# 5. Please provide FASTQ file extension (fastq.gz, fq.gz...)

source ~soft_bio_267/initializes/init_spring

input_folder=$1
output_folder=$2
FILES=$3
layout=$4
extension=$5

mkdir $output_folder

while IFS= read -r fname
do
	echo "Processing $fname"
	if [[ $layout == 'paired' ]]	
	then
	echo "Layout: $layout"	
		spring -c -i $input_folder/$fname'_1.'$extension $input_folder/$fname'_2.'$extension -o $output_folder/$fname.spring -g -t 16

	elif [[ $layout == 'single' ]]
	then
		spring -c -i $input_folder/$fname'_1.'$extension -o $output_folder/$fname.spring -g -t 16
	else
		echo "Error: wrong layout specified. Please choose paired or single."
	        exit 1
	fi
done < $FILES

