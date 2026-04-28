#! /usr/bin/env bash

html_file=$1
outfile=${html_file%.*}_fixed.html
rm $outfile

item_environment="none"
while IFS= read -r line; do
	if [[ "$line" == *"<iframe"* ]]; then
		item_environment="iframe"
	fi
	if [[ "$item_environment" == "iframe" ]]; then
		if [[ "$line" == "*</style>*" ]]; then
                        item_environment="iframe"
                fi
		if [[ "$line" == *"</iframe"* ]]; then
			item_environment="none"
		fi
		if [[ "$line" == '<style type="text/css">' ]]; then
			item_environment="knitr_style"
		fi
	fi
	if [[ "$item_environment" != "knitr_style" ]]; then
		echo "$line" >> $outfile
	fi
	if [[ "$item_environment" == "knitr_style" ]]; then
		if [[ "$line" == "</style>" ]]; then
			item_environment="iframe"
		fi
	fi
done < $html_file

