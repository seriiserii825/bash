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

wpShowPages(){
  wp post list --post_type=page --orderby=title --order=asc
}

select action in "${tgreen}Show pages${treset}" "${tblue}Ignore page${treset}" "${tmagenta}Exit${treset}"
do
  case $action in 
    "${tgreen}Show pages${treset}")
      wpShowPages
      echo "show pages"
      ;;
    "${tblue}Ignore page${treset}")
      wpShowPages
      ignorePage
      ;;
    "${tmagenta}Exit${treset}")
      exit 0
      ;;
  esac
done
