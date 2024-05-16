#! /bin/bash
args=("$@")

if [ ! $# -gt 0 -o ! $# -eq 2 ]; then
    echo "Set 'directory' and 'file'"
    exit 1
fi

if [ ! -f "src/pug/pages/index.pug" ]
  then
  echo "It's not a pug template"
  exit 1
fi

dir_name=$1
file_name=$2

function pugCreate(){
  # create directory and file
  dir_path="src/pug/blocks/$dir_name"
  mkdir -p  "$dir_path"

  file_path="$dir_path/$file_name.pug"
  touch "$file_path"

  # include file to front-page
  # sed -i -e "0,/get_footer/s#.*get_footer.*#<?php echo get_template_part('$wp_file_path');?>\n&#" front-page.php
  sed -i -e "0,/block scripts/s#.*block scripts.*#include ../blocks/$dir_name/$file_name\n&#" src/pug/pages/index.pug
}

function scssCreate(){
  # create scss directory
  mkdir -p "src/assets/sass/blocks/$dir_name"
  # create scss file
  scss_file_path="src/assets/sass/blocks/$dir_name/$file_name.scss"
  touch "$scss_file_path"
  # copy layout to file
  cat "src/assets/sass/blocks/layout.scss" > "$scss_file_path"
  # replace layout name
  sed -i -e "s/home/$file_name/g" "$scss_file_path" 

  # import scss file to my.scss
  echo "@import \"blocks/$dir_name"/"$file_name\";" >> src/assets/sass/my.scss
}

function jsCreate(){
  layout_path='template-parts/layouts/js-layout.ts'

  mkdir -p  "src/js/modules/$dir_name"
  touch  "src/js/modules/$dir_name"/"$file_name.ts"

  file_path="src/js/modules/$dir_name/$file_name.ts"
  cat "$layout_path" > $file_path 
  echo "Give function name with camelCase: "
  read function_name
  sed -i -e "s/jsLayout/$function_name/g" "$file_path" 
}

select choice in pug scss 
do
  case $choice in
    pug)
      pugCreate
      scssCreate
      break
      ;;
    scss)
      scssCreate
      break
      ;;
    *)
      echo "Please select 1 or 2"
      ;;
  esac
done


