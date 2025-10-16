#!/bin/bash

# Optional: quick dependency check
if ! command -v trans &>/dev/null; then
  echo "${tmagenta}trans-shell is not installed. Installing (requires sudo)…${treset}"
  sudo pacman -S --noconfirm gawk trans-shell
fi
if ! command -v xclip &>/dev/null; then
  echo "${tmagenta}xclip is not installed. Installing (requires sudo)…${treset}"
  sudo pacman -S --noconfirm xclip
fi
if ! command -v xsel &>/dev/null; then
  echo "${tmagenta}xsel is not installed. Installing (requires sudo)…${treset}"
  sudo pacman -S --noconfirm xsel
fi

convet_to_slug(){
  declare -g to_slug
  echo "${tblue}Do you want to convert the text to slug format? (y/n)${treset}"
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    to_slug=true
  else
    to_slug=false
  fi
}

choose_lang() {
  declare -g lang
  echo "${tgreen}Select target language:${treset}"
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
  translated_text=$(trans -b ":$lang" "$clipboard" | tr -d '\n')
  if [ "$to_slug" = true ]; then
    translated_text=$(echo "$translated_text" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')
  fi
  echo "${tgreen}Translated text: $translated_text${treset}"
  echo -n "$translated_text" | xclip -selection clipboard
}

# 1) Choose language once
choose_lang
convet_to_slug

# — вспомогательные функции для построчного режима —
reload_clipboard_lines() {
  clipboard_all=$(xclip -o -selection clipboard 2>/dev/null)
  if [[ -z "$clipboard_all" ]]; then
    echo "Clipboard is empty. Copy some text and press Enter to try again (q to quit)…"
    read -r ans
    [[ "$ans" =~ ^[Qq]$ ]] && return 1
    clipboard_all=$(xclip -o -selection clipboard 2>/dev/null)
    [[ -z "$clipboard_all" ]] && { echo "Still empty."; return 1; }
  fi
  # Без нулевых байтов: просто делим по переводам строк
  mapfile -t clipboard_lines <<< "$clipboard_all"
  current_idx=0
  return 0
}

translate_current_line() {
  # Пропускаем пустые строки
  while (( current_idx < ${#clipboard_lines[@]} )) && [[ -z "${clipboard_lines[$current_idx]}" ]]; do
    ((current_idx++))
  done
  if (( current_idx >= ${#clipboard_lines[@]} )); then
    return 1
  fi

  local line="${clipboard_lines[$current_idx]}"
  translated_text=$(trans -b ":$lang" "$line" | tr -d '\n')
  if [ "$to_slug" = true ]; then
    translated_text=$(echo "$translated_text" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g' \
      | sed -E 's/^-+|-+$//g')
  fi

  echo "${tgreen}[$((current_idx+1))/${#clipboard_lines[@]}] → $translated_text${treset}"
  printf '%s' "$translated_text" | xclip -selection clipboard
}

# Первая загрузка буфера
reload_clipboard_lines || exit 0

# 2) Main loop: по одной строке за Enter
while true; do
  if ! translate_current_line; then
    echo
    read -rp "No more lines. (r=reload clipboard, l=change language, n=quit): " choice
    case "$choice" in
      r|R) reload_clipboard_lines || continue ;;
      l|L) choose_lang ;;               # язык сменили, продолжаем с той же позиции
      n|N|q|Q) echo "Exiting translator."; break ;;
      *) : ;;
    esac
    continue
  fi

  # Переведена текущая — двигаем индекс и ждём команду
  ((current_idx++))
  echo
  read -rp "Continue with same language [$lang]? (Enter=next line, l=change language, r=reload, n=quit): " choice
  case "$choice" in
    l|L) choose_lang ;;                 # язык сменили, индекс не трогаем
    r|R) reload_clipboard_lines || continue ;;
    n|N|q|Q) echo "Exiting translator."; break ;;
    *) : ;;                             # Enter → идём на следующую строку
  esac
done
