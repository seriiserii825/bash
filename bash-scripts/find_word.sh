#!/bin/bash

read -p "Enter a word: " word
read -p "Enter file_type: " file_type

grep --color=always -Rnw . -e $word  --include=*.$file_type
