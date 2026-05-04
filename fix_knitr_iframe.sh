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
			item_environment="none" # This was set to "iframe" but then it would potentially remove more than one style inside the iframe. The line that matches the knitr style should only ever exact match the problematic style, but this ensures NO matches further than the first will ever occur. Ping me #alvaro if you ever have trouble with the script
		fi
	fi
done < $html_file

