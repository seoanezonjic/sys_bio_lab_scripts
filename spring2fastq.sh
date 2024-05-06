#!/usr/bin/env bash
#SBATCH --cpus-per-task=16
#SBATCH --mem='100gb'
#SBATCH --time='1-10:00:00'
#SBATCH --constraint=cal
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out

# Script to decompress spring files to fastq. 
# Works with single and paired reads.
# Please provide as input arguments: 
# 1. Input folder path with SPRING files
# 2. Output folder path where fastq files will be saved
# 3. File path with filenames of SPRING files to decompress
# 4. Please choose layout: single or paired

source ~soft_bio_267/initializes/init_spring

input_folder=$1
output_folder=$2
FILES=$3 #path to file with filenames
layout=$4

mkdir -p $2

while IFS= read -r fname
do
  echo "Processing $fname"
  if [[ $layout = 'paired' ]]
  then
	  spring -d -i $input_folder/$fname'.spring' -o $output_folder/$fname'_1.fastq.gz' $output_folder/$fname'_2.fastq.gz' -g -t 16
  elif [[ $layout == 'single' ]] 
  then
	  spring -d -i $input_folder/$fname'.spring' -o $output_folder/$fname'_1.fastq.gz' -g -t 16
  else
	echo "Error: wrong layout specified. Please choose paired or single."
	exit 1
  fi
done < $FILES

