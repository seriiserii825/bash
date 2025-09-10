#!/bin/bash

# Optional: quick dependency check
if ! command -v trans &>/dev/null; then
  echo "trans-shell is not installed. Installing (requires sudo)…"
  sudo pacman -S --noconfirm gawk trans-shell
fi
if ! command -v xclip &>/dev/null; then
  echo "xclip is not installed. Installing (requires sudo)…"
  sudo pacman -S --noconfirm xclip
fi
if ! command -v xsel &>/dev/null; then
  echo "xsel is not installed. Installing (requires sudo)…"
  sudo pacman -S --noconfirm xsel
fi

choose_lang() {
  echo "Select target language:"
  select lang in "en" "it" "ru" "ro" "de" "fr"; do
    case $lang in
      en|it|ru|ro|de|fr) echo "Language selected: $lang"; break ;;
      *) echo "ERROR! Please select between 1..6" ;;
    esac
  done
}

translate_clipboard() {
  local clipboard
  clipboard=$(xclip -o -selection clipboard 2>/dev/null)

  if [[ -z "$clipboard" ]]; then
    echo "Clipboard is empty. Copy some text and press Enter to try again (q to quit)…"
    read -r ans
    [[ "$ans" =~ ^[Qq]$ ]] && return 1
    clipboard=$(xclip -o -selection clipboard 2>/dev/null)
    [[ -z "$clipboard" ]] && { echo "Still empty. Skipping."; return 0; }
  fi

  trans -b ":$lang" "$clipboard" | tr -d '\n' | xsel -b -i
  local copied_text
  copied_text=$(xsel -b -o)
  echo "Translated ($lang): $copied_text"
}

# 1) Choose language once
choose_lang

# 2) Main loop: each pass uses the same language and re-reads the clipboard
while true; do
  translate_clipboard || break

  echo
  read -rp "Continue with same language [$lang]? (Enter=yes, l=change language, n=quit): " choice
  case "$choice" in
    l|L) choose_lang ;;
    n|N|q|Q) echo "Exiting translator."; break ;;
    *) : ;; # Enter/anything else -> continue
  esac
done
