#!/usr/bin/env bash

files=`find $FSCRATCH| tr "\n" " "`
touch $files
