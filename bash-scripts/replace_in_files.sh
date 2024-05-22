#!/bin/bash

read -p "Enter a word: " word
read -p "Enter file_type: " file_type

find -name "*.$file_type" -exec sed -i "s/$word/REPLACED/g" {} \;
