#! /bin/bash

# toogle case
st1='camelCase'
lower_case=$(echo "$st1" | tr '[:upper:]' '[:lower:]')
upper_case=$(echo "$st1" | tr '[:lower:]' '[:upper:]')
first_letter_capital=$(echo "$st1" | sed 's/.*/\u&/')

# # replace first occurience
string="Welcome to bash script."
string=$(echo "$string" | sed "s/bash/shell/")

## replace all ocurrience
string=$(echo "$string" | sed "s/bash/shell/g")

### get element from path

cat filelist.txt
./first/example1/path
./second/example1/path
./third/example2/path

cut -d/ -f2 filelist.txt
first
second
third

## string contains substring
if [[ "$file_path" != *"json"* ]]; then
  echo "${tmagenta}File is not json${treset}"
  exit 1
fi
