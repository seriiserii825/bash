#!/bin/bash

# check if trans-shell is installed

if ! [ -x "$(command -v trans)" ]
then
  echo "${tmagenta}trans-shell is not installed. Please install it first.${treset}"
  sudo apt install gawk
  wget git.io/trans
  chmod +x ./trans
  sudo mv trans /usr/bin/
fi
clipboard=$(xclip -o -selection clipboard)


select lang in "en" "it" "ru" "ro" "de" "fr"
do
  case $lang in
    "en")
      trans -b :en "$clipboard" | tr -d '\n' | xsel -b -i 
      break
      ;;
    "it")
      trans -b :it "$clipboard"  | tr -d '\n' | xsel -b -i 
      break
      ;;
    "ru")
      trans -b :ru "$clipboard"  | tr -d '\n' | xsel -b -i 
      break
      ;;
    "ro")
      trans -b :ro "$clipboard"  | tr -d '\n' | xsel -b -i 
      break
      ;;
    "de")
      trans -b :de "$clipboard"  | tr -d '\n' | xsel -b -i 
      break
      ;;
    "fr")
      trans -b :fr "$clipboard"  | tr -d '\n' | xsel -b -i 
      break
      ;;
    *)
      echo "ERROR! Please select between 1..6";;
  esac
done

