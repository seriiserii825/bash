#! /bin/bash

file_path=$( fzf )
mogrify -resize x900 $file_path
jpegoptim --strip-all --all-progressive -ptm 80 $file_path
