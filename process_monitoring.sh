#! /usr/bin/env bash


command_name=$1
output_file=$2

echo COMMAND_NAME IS $command_name
echo OUTPUT_FILE IS $output_file

if [ -z "${output_file}" ]; then
	echo ERROR: NO OUTPUT FILE SPECIFIED
	exit 1
fi

sleep 5

process_pid=`pidof $command_name`
if [ "$?" == 0 ]; then
	rm $output_file
	while [ ! -z "`ps | grep $process_pid`" ]; do 
		ps -p $process_pid -o %cpu,%mem,etime | sed -n "2p" > $output/timepoint_data
		awk 'BEGIN{OFS="\t"}{print $1,$2,$3}' $output/timepoint_data >> $output_file
		sleep 5
	done
fi
