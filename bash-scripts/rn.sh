#! /bin/bash 

# if not installed perl-rename
if ! command -v perl-rename &> /dev/null
then
  echo "${tred}perl-rename is not installed${treset}"
  sudo pacman -S perl-rename
fi


function renameSymbol(){
    read -p "${tgreen}Enter the symbol to replace: ${treset}" symbol
    if [ -z "$symbol" ]
    then
      echo "${tred}Symbol can't be empty${treset}"
      renameSymbol
    fi
    read -p "${tblue}Enter the new symbol: ${treset}" new_symbol
    for I in *; 
      ## show changed file but don't change
    do echo "$I" | sed "s/$symbol/$new_symbol/g";done
    sleep 1
    read -p "${tmagenta}Apply changes? (y/n): ${treset}" answer
    if [ $answer == "y" ]
    then
      for I in *; 
      do mv "$I" `echo "$I" | sed "s/$symbol/$new_symbol/g"`;done
    fi
}

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
    read -p "${tgreen}Enter extension, leave empty for jpg: ${treset}" extension
    if [ -z "$extension" ]
    then
      extension="jpg"
    fi
    perl-rename 's/(\d+)/sprintf("%03d", $1)/e' *.$extension
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
    renameSymbol
    menu
  elif [ $option -eq 4 ]
  then
    read -p "${tgreen}Enter the prefix: ${treset}" prefix
    read -p "${tblue}Enter extension, leave empty for jpg:${treset}" extension
    if [ -z "$extension" ]
    then
      extension="jpg"
    fi
    x=0
    for i in `ls *.$extension`;do mv "$i" $prefix-$[++x].$extension ;done
    menu
  elif [ $option -eq 5 ]
  then
    read -p "${tgreen}Enter extension, leave empty for jpg: ${treset}" extension
    if [ -z "$extension" ]
    then
      extension="jpg"
    fi
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
