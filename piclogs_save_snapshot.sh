#!/usr/bin/env bash
logs_dir=~pedro/piclogs/logs
#filename=`date +"%Y_%m_%d_%H_%M_%S"`
current_timestamp=$(date +%s)
current_log_file=$logs_dir/$current_timestamp

last_timestamp=$(ls $logs_dir | sort -nr | head -n 1)
if [[ $((current_timestamp - last_timestamp)) -gt 1800 || $last_timestamp -eq 0 ]]; then #30 minutes difference or more
    scontrol show node > $current_log_file
fi
