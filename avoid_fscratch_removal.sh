#!/usr/bin/env bash

files=`find $FSCRATCH`
files=`echo $files | tr " " "\n"`
limit=`echo -e "$files"| wc -l`
processed_files=1
while [ $processed_files -le $limit ]
do
	files_chunk=`echo -e "$files" | tail -n +$processed_files |head -n 1000| tr "\n" " "`
	touch $files_chunk
	processed_files=$(( $processed_files + 1000 ))
done

