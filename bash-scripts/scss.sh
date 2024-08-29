#!/bin/bash

if [[ ! -f front-page.php ]]; then
  echo "${tmagenta}Go to the root of the project${treset}"
  exit 1
fi

script_path=$(dirname "$0")
projects_dir="$script_path/wp-projects"
current_dir_name=${PWD##*/}
variable_file_path="$projects_dir/$current_dir_name.sh"

## check if in projects_dir exists file current_dir_name.php
if [[ ! -f $variable_file_path ]]; then
  echo "${tmagenta}File $current_dir_name.php not found in $projects_dir${treset}"
  touch $variable_file_path
  echo "${tmagenta}Add scss variables in $variable_file_path${treset}"
  exit 1
fi

## if $variable_file_path is empty
if [ ! -s $variable_file_path ]; then
  echo "${tmagenta}File $variable_file_path is empty${treset}"
  exit 1
fi

function convertToRem(){
  scss_file=$1
  while read -r line; do
    if [[ $line == *"border:"* || $line == *"border-bottom:"* || $line == *"max-width"* || $line == *"linear-gradient"* || $line == *"&"* || $line == *"width: 0.1rem ;"* || $line == *"height: 1px;"* ]]; then
      # echo "$line"
      continue
    else
      # Use regular expressions to find pixel values (e.g., "10px", "20px", etc.)
      px_values=$(echo "$line" | grep -oE "[0-9]+px")
      new_line="$line"

    # Iterate through each found pixel value
    for px_value in $px_values; do
      # Extract the numeric value from the pixel value
      numeric_value=$(echo "$px_value" | grep -oE "[0-9]+")

      # Convert the pixel value to rem and divide by 10
      rem_value=$(awk "BEGIN { printf \"%.2f\", $numeric_value / 10 }")

      # Replace the pixel value with the calculated rem value
      new_line=$(echo "$new_line" | sed "s/$px_value/${rem_value}rem/g")

      # echo "'new_line is:' $new_line"
    done
    # Print the modified line
    # echo "$line"
    # echo "$new_line"
    sed -i "s/$line/$new_line/" $scss_file > /dev/null 2>&1
    fi
  done < "$scss_file"
  yarn prettier --write $scss_file > /dev/null 2>&1
}

function scssHandler(){
  variable_file_path=$1
  clipboard=$(xclip -o -selection clipboard)
  scss_file=~/Downloads/scss.scss
  touch $scss_file
  # remove lines
  echo "$clipboard" > $scss_file
  sed -i '/Clash Display/d' $scss_file
  sed -i '/font-style: normal/d' $scss_file
  sed -i '/line-height: normal/d' $scss_file
  # sed -i 's/var(--White, #FFF);/#fff;/g' $scss_file
  # replace
  while read -r line; do
    first=$(echo $line | cut -d',' -f1)
    second=$(echo $line | cut -d',' -f2)
    # if line is not empty
    if [ -z "$line" ]; then
      continue
    fi
    if [[ $first == *"--"* ]]; then
      # set -x
      colors=(--White)
      for color in "${colors[@]}"; do
        if [[ $first == *"$color"* ]]; then
          sed -i "s/var($first, #[0-9A-Fa-f]\{6\});/$second;/g" $scss_file
          continue
        fi
      done
      sed -i "s/var($first, #[0-9A-Fa-f]\{6\});/var($second);/g" $scss_file
      # set +x
    else
      sed -i "s/$first/var($second)/g" $scss_file
    fi
  done < "$variable_file_path"
  # line-height line if it's not normal, convert to fraction, divide line-height by font-size
  line_height=$(grep "line-height" $scss_file)
  if [[ $line_height != *"normal"* ]]; then
    # get line-height value from line: line-height: 20px;
    line_height=$(grep -oE "line-height: [0-9]+px;" $scss_file)
    # from line-height: 20px; get 20px
    line_height_value=$(echo $line_height | grep -oE "[0-9]+")
    font_size=$(grep -oE "font-size: [0-9]+px;" $scss_file)
    font_size_value=$(echo $font_size | grep -oE "[0-9]+")
    #fraction divide line-height by font-size
    fraction=$(awk "BEGIN { printf \"%.2f\", $line_height_value / $font_size_value }")
    sed -i "s/$line_height/line-height: $fraction;/" $scss_file
  fi


  convertToRem $scss_file



  ## line starts with color delete from current line and move to the bottom
  line_with_color=$(grep -n "color" $scss_file | cut -d: -f2-)
  sed -i "/color/d" $scss_file
  echo $line_with_color >> $scss_file

  ## line starts with text-align delete and move before color or line-height
  line_with_text_align=$(grep -n "text-align" $scss_file | cut -d: -f2-)
  sed -i "/text-align/d" $scss_file
  # find line number of color or line-height
  line_number=$(grep -n "color\|line-height" $scss_file | cut -d: -f1)
  # insert text-align before color or line-height
  sed -i "${line_number}i $line_with_text_align" $scss_file

  line_with_background=$(grep -n "background" $scss_file | cut -d: -f2-)
  sed -i "/background/d" $scss_file
  echo $line_with_background >> $scss_file
  # remove all empty lines in file
  sed -i '/^$/d' $scss_file
  bat $scss_file
  xclip -sel clip < $scss_file
  clipboard=$(cat $scss_file)
  notify-send "$(echo -e "$clipboard")" 
  rm $scss_file
}

while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  clipboard=$(xclip -o -selection clipboard)
  # if in clipboard have css rule then run like property: value;
  if [[ $clipboard == *":"* ]]; then
    scssHandler $variable_file_path
  fi
done

# + sed -i 's/var(--White, #[0-9A-Fa-f]\{6\});/ #FFF;/g' /home/serii/Downloads/scss.scss
# + sed -i 's/var(--Blue-Darkest, #[0-9A-Fa-f]\{6\});/var(--accent-darkest);/g'
