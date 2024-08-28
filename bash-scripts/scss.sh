#!/bin/bash

function scssHandler(){
  # sleep 1
  clipboard=$(xclip -o -selection clipboard)
  scss_file=~/Downloads/scss.scss
  touch $scss_file
  echo "$clipboard" > $scss_file
  sed -i '/Clash Display/d' $scss_file
  sed -i '/font-style: normal/d' $scss_file
  sed -i '/line-height: normal/d' $scss_file
  # replace
  sed -i 's/Montserrat/var(--font-3)/g' $scss_file
  sed -i 's/var(--Blue-Darkest, #[0-9A-Fa-f]\{6\});/var(--accent-darkest);/g' $scss_file
  sed -i 's/var(--White, #FFF);/#fff;/g' $scss_file

  # line-height line if it's not normal, convert to fraction, divide line-height by font-size
  line_height=$(grep "line-height" $scss_file)
  if [[ $line_height != *"normal"* ]]; then
    # get line-height value from line: line-height: 20px;
    line_height=$(grep -oE "line-height: [0-9]+px;" $scss_file)
    echo $line_height
    # from line-height: 20px; get 20px
    line_height_value=$(echo $line_height | grep -oE "[0-9]+")
    echo $line_height_value
    font_size=$(grep -oE "font-size: [0-9]+px;" $scss_file)
    font_size_value=$(echo $font_size | grep -oE "[0-9]+")
    echo $font_size_value
    #fraction divide line-height by font-size
    fraction=$(awk "BEGIN { printf \"%.2f\", $line_height_value / $font_size_value }")
    echo $fraction
    sed -i "s/$line_height/line-height: $fraction;/" $scss_file
  fi


  convertToRem $scss_file



  ## line starts with color delete from current line and move to the bottom
  line_with_color=$(grep -n "color" $scss_file | cut -d: -f2-)
  sed -i "/color/d" $scss_file
  echo $line_with_color >> $scss_file

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
    scssHandler
  fi
done
