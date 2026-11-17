#!/usr/bin/env bash
scontrol_dir=~pedro/piclogs/logs
squeue_logs=~pedro/piclogs/sq_logs
#filename=`date +"%Y_%m_%d_%H_%M_%S"`
current_timestamp=$(date +%s)
control_log_file=$scontrol_dir/$current_timestamp
sq_log_file=$squeue_logs/$current_timestamp

last_timestamp=$(ls $scontrol_dir | sort -nr | head -n 1)
if [[ $((current_timestamp - last_timestamp)) -gt 1800 || $last_timestamp -eq 0 ]]; then #30 minutes difference or more
    scontrol show node > $control_log_file
    squeue | grep -oP '(USERS|JOBS|CPUS): [0-9]+' | sed 's/: /\t/g' > $sq_log_file
fi
