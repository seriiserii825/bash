#! /bin/bash


# Infinite loop to continuously prompt for file names and perform actions
while true; do
  # Prompt the user to enter a file name
  # echo "Please enter a file name:"
  # read filename

  file_path=$( fzf )
  # Check if the file exists
  if [[ $file_path == *.jpg ]]; then
    echo "Processing $file_path"
    sleep 1
    mogrify -resize x900 $file_path
    jpegoptim --strip-all --all-progressive -ptm 80 $file_path
    sleep 1
  else
    echo "File '$file_path' does not exist."
  fi

    # Add a separator for clarity
    echo "----------------------------------------"
  done
