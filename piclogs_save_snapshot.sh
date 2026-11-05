#!/usr/bin/env bash
logs_dir=~pedro/piclogs
filename=`date +"%Y_%m_%d_%H_%M_%S"`
current_log_path=$logs_dir/$filename.log
tar_DB_path="$logs_dir/piclogs.tar"
last_timestamp_path=$logs_dir/last_timestamp.txt

current_timestamp=$(date +%s)
last_timestamp=$(cat $last_timestamp_path 2>/dev/null || echo 0)
if [[ $((current_timestamp - last_timestamp)) -gt 900 || $last_timestamp -eq 0 ]]; then #15 minutes difference or more
    if [ ! -f $tar_DB_path ]; then tar -cf $tar_DB_path --files-from=/dev/null; fi 
    scontrol show node > $current_log_path
    #Vamos añadiendo el archivo a un tar (existente o no) con append. (Para evitar ir creciendo la cantidad de archivos y darnos con un límite de archivos)
    tar -rf $tar_DB_path -C "$logs_dir" "$filename.log" && rm "$current_log_path"
    echo $current_timestamp > $last_timestamp_path
fi
