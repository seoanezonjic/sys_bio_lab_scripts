#! /usr/bin/env bash


curr_dir=`pwd`
while [ TRUE ]; do
	echo "It lives" > $curr_dir/alive.file
	sleep 850
	echo "Die" > $curr_dir/alive.file
	rm $curr_dir/alive.file
done

