#!/bin/bash

read -p "Enter the directory from downloads: " dist
if [ -z $dist ]; then
    echo "${tmagenta}Directory cannot be empty.${treset}"
    exit 1
fi

dir_path=~/Downloads/$dist

if [ ! -d $dist ]; then
    mkdir $dir_path  
fi

read -p "Enter file extension, by default mp4: " ext
if [ -z $ext ]; then
    ext="mp4"
fi

find . -name "*.$ext" | xargs -I {} cp {} $dir_path
