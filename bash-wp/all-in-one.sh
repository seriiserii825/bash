#!/bin/bash

full_url="";
file_find=$(find -name "front-page.php");

if [ -z "$file_find" ]; then
    echo "Go to wp project theme.";
else
  current_path=$(pwd);
  IFS='/' read -r -a array <<< "$current_path"

  for index in "${!array[@]}"
  do
    element=${array[index]}
    if [ "$element" == "app" ]; then
      break;
      elif [ "$index" -ne 0 ]; then
      full_url="$full_url/${element}";
    fi
  done

  file_path='conf/php/php.ini.hbs';
  full_file_path="$full_url/$file_path";

  # echo "full file path: $full_file_path";

  if [ -f $full_file_path ]; then
    grep "upload_max_filesize" $full_file_path;
    read -p "Enter mb: " mb
    sed -i "s/^upload_max_filesize.*/upload_max_filesize = ${mb}M/" $full_file_path;
    grep "upload_max_filesize" $full_file_path;
  else
    echo "File not found!";
    exit 1;
  fi
fi

# ancestor() {
#   local n=${1:-1}
#   (for ((; n != 0; n--)); do cd $(dirname ${PWD}); done; pwd)
# }
