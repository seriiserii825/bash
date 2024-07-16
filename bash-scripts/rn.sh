#! /bin/bash 

function menu(){
  exa -la
  echo "${tblue}1) Rename digits${treset}"
  echo "${tgreen}2) Replace spaces${treset}"
  echo "${tblue}3) Replace symbols${treset}"
  echo "${tgreen}4) Rename images${treset}"
  echo "${tblue}5) Add prefix${treset}"
  echo "${tmagenta}6) Exit${treset}"

  read -p "Choose an option: " option
  if [ $option -eq 1 ]
  then
    perl-rename 's/\d+/sprintf(\"%03d\", $&)/e'
    menu
  elif [ $option -eq 2 ]
  then
    perl-rename 's/ /-/g' *
    perl-rename 's/----/-/g' *
    perl-rename 's/---/-/g' *
    perl-rename 's/--/-/g' *
    menu
  elif [ $option -eq 3 ]
  then
    read -p "${tgreen}Enter the symbol to replace: ${treset}" symbol
    read -p "${tblue}Enter the new symbol: ${treset}" new_symbol
    perl-rename -v s/$symbol/$new_symbol/g *
    sleep 1
    read -p "${tmagenta}Apply changes? (y/n): ${treset}" answer
    if [ $answer == "y" ]
    then
      perl-rename -n s/$symbol/$new_symbol/g *
    fi
    menu
  elif [ $option -eq 4 ]
  then
    read -p "${tgreen}Enter the prefix: ${treset}" prefix
    read -p "${tblue}Enter extension:${treset}" extension
    x=0
    for i in `ls *.$extension`;do mv "$i" $prefix-$[++x].$extension ;done
    menu
  elif [ $option -eq 5 ]
  then
    read -p "${tgreen}Enter extension: ${treset}" extension
    read -p "${tblue}Enter prefix: ${treset}" prefix
    for filename in *.$extension; do mv "$filename" "$prefix-${filename}"; done;
  elif [ $option -eq 6 ]
  then
    exit 0
  else
    echo "Invalid option"
    menu
  fi
}

menu
