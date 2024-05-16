#!/bin/bash

file_path="files_with_text.txt"

function findInFiles(){
  read -p "Enter the text to search: " text
  grep --color="always" -Rnw . -e "$text"
}

function saveFindsInFile(){
  read -p "Enter the text to search: " text
  grep -Rnw . -e "$text" > $file_path
  sed -i "s/:.*$//" $file_path
}

function replaceInFiles(){
  read -p "Enter the text to replace: " text
  read -p "Enter the new text: " new_text

  for line in $(cat $file_path); do
    sed -i "s/$text/$new_text/g" $line
  done
}

function viewFile(){
  bat $file_path
}

function main(){
  echo "${tgreen}1. Find in files${treset}"
  echo "${tblue}2. Save finds in file${treset}"
  echo "${tblue}2.2 View file${treset}"
  echo "${tyellow}3. Replace in files${treset}"
  echo "${tmagenta}4. Exit${treset}"
  read -p "Enter the option: " option

  case $option in
    1)
      findInFiles
      main
      ;;
    2)
      saveFindsInFile
      main
      ;;
    2.2)
      viewFile
      main
      ;;
    3)
      replaceInFiles
      main
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
}
main

