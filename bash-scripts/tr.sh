#!/bin/bash

# check if trans-shell is installed

if ! [ -x "$(command -v trans)" ]
then
  echo "${tmagenta}trans-shell is not installed. Please install it first.${treset}"
  sudo pacman -S gawk
  sudo pacman -S trans-shell
fi
clipboard=$(xclip -o -selection clipboard)


select lang in "en" "it" "ru" "ro" "de" "fr"
do
  case $lang in
    "en")
      trans -b :en "$clipboard" | tr -d '\n' | xsel -b -i 
      copied_text=$(xsel -b -o)
      echo "$copied_text"
      break
      ;;
    "it")
      trans -b :it "$clipboard"  | tr -d '\n' | xsel -b -i 
      copied_text=$(xsel -b -o)
      echo "$copied_text"
      break
      ;;
    "ru")
      trans -b :ru "$clipboard"  | tr -d '\n' | xsel -b -i 
      copied_text=$(xsel -b -o)
      echo "$copied_text"
      break
      ;;
    "ro")
      trans -b :ro "$clipboard"  | tr -d '\n' | xsel -b -i 
      copied_text=$(xsel -b -o)
      echo "$copied_text"
      break
      ;;
    "de")
      trans -b :de "$clipboard"  | tr -d '\n' | xsel -b -i 
      copied_text=$(xsel -b -o)
      echo "$copied_text"
      break
      ;;
    "fr")
      trans -b :fr "$clipboard"  | tr -d '\n' | xsel -b -i 
      copied_text=$(xsel -b -o)
      echo "$copied_text"
      break
      ;;
    *)
      echo "ERROR! Please select between 1..6";;
  esac
done

