#! /bin/bash 

file_path=$(fzf)
file_name=$(basename $file_path)
file_name_without_extension="icon"
file_extension=$(echo $file_name | cut -d'.' -f2)
file_128="$file_name_without_extension-128.$file_extension"
cp $file_path $file_128
file_48="$file_name_without_extension-48.$file_extension"
cp $file_path $file_48
file_32="$file_name_without_extension-32.$file_extension"
cp $file_path $file_32
file_16="$file_name_without_extension-16.$file_extension"
cp $file_path $file_16

mogrify -resize 128"x" $file_128
mogrify -resize 48"x" $file_48
mogrify -resize 32"x" $file_32
mogrify -resize 16"x" $file_16
