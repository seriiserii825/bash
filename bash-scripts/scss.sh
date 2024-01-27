#!/bin/bash

read -p "Enter class names separated by space: " class_names
cd ~/Downloads
file_name=styles.scss
if [ -f $file_name ]; then
  rm $file_name
  touch $file_name
else
  touch $file_name
fi

for class_name in $class_names
do
  echo "&__${class_name} {}" >> $file_name
done

bat $file_name
xclip -selection clipboard $file_name
rm $file_name

# acf_path=~/Downloads/acf.txt
# output_path=~/Downloads/output.txt
# touch $acf_path
# touch $output_path


# echo "$(xclip -o -selection clipboard)" > $acf_path

# bat $acf_path
# # >$output_path

# echo "\$$field_group_name = get_field('$field_group_name');" > $output_path
# while read -r line; do
#   new_line="\$$line=\$$field_group_name['$line'];"
#   echo $new_line >> $output_path
# done < "$acf_path"

# bat $output_path
# xclip -selection clipboard $output_path

# rm $acf_path
# rm $output_path
