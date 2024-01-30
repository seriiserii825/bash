#! /bin/bash
if [ ! -f "front-page.php" ]
then
  echo "${terror}front-page.php not found, it's not a wordpress template${treset}"
  exit 1
fi

source ~/Documents/bash/bash-wp/wp-helper.sh

function ignorePage(){
  read -p "Enter the page ID to ignore: " page_id
  line=$(awk '/\$ids/{print NR; exit}' inc/func.php)
  sed -i  "${line} s/];/,${page_id}];/" inc/func.php
}

select action in "Show pages" "Ignore page" "Exit"
do
  case $action in 
    "Show pages")
      wpShowPages
      echo "show pages"
      ;;
    "Ignore page")
      wpShowPages
      ignorePage
      ;;
    "Exit")
      exit 0
      ;;
  esac
done
