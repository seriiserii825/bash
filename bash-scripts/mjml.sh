#!/bin/bash

# check if mjml is installed
if ! [ -x "$(command -v mjml)" ]; then
  echo 'Error: mjml is not installed.'
  npm install -g mjml
fi

output_dir="output"
if [ ! -d "$output_dir" ]; then
  mkdir $output_dir
fi

# list throw all mjml files in the projects directory and compile them to html in output directory
for file in $(find ./projects -name "*.mjml")
do
  filename=$(basename -- "$file")
  filename="${filename%.*}"
  mjml $file -o $output_dir/$filename.html
  echo "compiled $file to $output_dir/$filename.html"
done

