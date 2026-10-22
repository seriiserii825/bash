#!/bin/bash
# Chrome extensions repos manager: dump repo urls to file, clone repos from file

source /home/serii/dotfiles/zsh_modules/zsh_colors

root=~/Documents/chrome-extensions
urls_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/chrome-extensions-repos-urls.txt"

function reposToFile() {
  touch "$urls_file"

  for dir in "$root"/*/; do
    [ -d "$dir/.git" ] || continue
    local url
    url=$(git -C "$dir" remote get-url origin 2>/dev/null)
    [ -z "$url" ] && continue

    if grep -qxF "$url" "$urls_file"; then
      echo "Уже есть: $url"
    else
      echo "Добавляю: $url"
      echo "$url" >> "$urls_file"
    fi
  done
}

function cloneRepos() {
  if [ ! -f "$urls_file" ]; then
    echo "${tred}Файл $urls_file не найден${treset}"
    return 1
  fi

  mkdir -p "$root"

  while IFS= read -r url; do
    [ -z "$url" ] && continue

    local name
    name=$(basename "$url" .git)
    local dir="$root/$name"

    if [ -d "$dir" ]; then
      echo "Уже существует: $name"
      continue
    fi

    echo "Клонирую $url..."
    if ! git clone "$url" "$dir"; then
      echo "${tred}Не удалось клонировать $url${treset}"
    fi
  done < "$urls_file"
}

echo "${tblue}1) Chrome extensions repos to file${treset}"
echo "${tmagenta}2) Clone chrome extensions repos${treset}"
echo "3) Exit"
read -rp "Select an option: " option

case $option in
  1)
    reposToFile
    ;;
  2)
    cloneRepos
    ;;
  3)
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac
