#! /bin/bash 

function renameDigits(){
  echo "File or Directory? f/d"
  read type
  if [ $type = "f" ]; then
    ls -la
    # get extension from user input
    echo "Enter extension"
    read extension
    echo $extension
    for file in *.$extension; do
      # check if file hase space in name
      if [[ $file =~ [[:space:]] ]]; then
        # replace space with underscore
        new_file_name=$(echo $file | tr ' ' '_')
        mv "$file" $new_file_name
      fi
    done
    # loop throw all files with extension
    for file in *.$extension; do
      first_digits_from_file=$(echo $file | grep -o '^[0-9]\+')
      # if file starts with digit and digit length == 1 change from 1 to 01
      if [[ $file =~ ^[1-9] && ${#first_digits_from_file} -eq 1 ]]; then
        mv $file 0$file
      fi
    done
    ls -la
  elif [ $type = "d" ]; then
    ls -la
    # check if dir has space in name
    for dir in [0-9]*; do
      if [[ $dir =~ [[:space:]] ]]; then
        # replace space with underscore
        new_dir_name=$(echo $dir | tr ' ' '_')
        mv "$dir" $new_dir_name
      fi
    done
    # loop dirs that starts with digits
    for dir in [0-9]*; do
      first_digits_from_file=$(echo $dir | grep -o '^[0-9]\+')
      #all dirs starts with digit change from 1 to 01
      if [[ $dir =~ ^[1-9] && ${#first_digits_from_file} -eq 1 ]]; then
        mv $dir 0$dir
      fi
    done
    ls -la
  else
    echo "Wrong input"
    exit 1
  fi
}

renameDigits
