#!/bin/bash

# Check if trans-shell is installed
if ! command -v trans &> /dev/null; then
  echo "trans-shell is not installed. Please install it first."
  sudo pacman -S gawk trans-shell
fi

while true; do
  clipboard=$(xclip -o -selection clipboard)

  echo "Select target language:"
  select lang in "en" "it" "ru" "ro" "de" "fr"; do
    case $lang in
      en|it|ru|ro|de|fr)
        trans -b :$lang "$clipboard" | tr -d '\n' | xsel -b -i
        copied_text=$(xsel -b -o)
        echo "Translated ($lang): $copied_text"
        break
        ;;
      *)
        echo "ERROR! Please select between 1..6"
        ;;
    esac
  done

  read -p "Do you want to continue translating? (y/n): " choice
  if [[ $choice != "y" ]]; then
    echo "Exiting translator."
    break
  fi
done
