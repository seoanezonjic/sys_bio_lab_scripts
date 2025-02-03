#! /usr/bin/env bash


process_id=$1
if [ ! -z "ps | grep $process_id" ]; then
	while [ -s timepoint_data ]; do 
		ps -p $process_pid -o %cpu,%mem,etime | sed -n "2p" > timepoint_data
		cat timepoint_data >> execution_metrics
		sleep 1
	done
	awk 'BEGIN{ORFS="\t"}{print $1,$2,$3}' execution_metrics > tmp && mv tmp execution_metrics
fi
