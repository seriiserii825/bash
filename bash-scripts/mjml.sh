#!/bin/bash

# check if mjml is installed
if ! [ -x "$(command -v mjml)" ]; then
  echo 'Error: mjml is not installed.'
  npm install -g mjml
fi

# list throw all mjml files in the projects directory and compile them to html in output directory
for file in $(find ./projects -name "*.mjml")
do
  echo "Compiling $file"
  mjml $file -o "oputput/$(basename $file .mjml).html"
done

