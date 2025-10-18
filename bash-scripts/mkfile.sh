#!/usr/bin/env bash
# mkfile-and-edit: ask for file path, create dirs, open in Neovim

set -Eeuo pipefail

# Get clipboard content (using xclip)
target_path=$(xclip -selection clipboard -o)


# Check if it's a file
# Check if clipboard is not empty and does not end with a slash (not a directory)
if [[ -n "$target_path" \
      && "$target_path" == */* \
      && "$target_path" != */ \
      && ! "${target_path##*/}" =~ [\\/:*\?\"\<\>\|] \
      && "$target_path" != *" "* ]]; then
  echo "${tgreen}Clipboard contains a valid file path: $target_path${treset}"
else
  echo "${tmagenta}Clipboard does not contain a valid file path.${treset}"
  echo "Not empty path"
  echo "Path must contain at least one '/'"
  echo "Path must not end with '/'"
  echo "Filename must not contain invalid characters: \\ / : * ? \" < > |"
  echo "Path must not contain spaces"
  exit 1
fi

# 4) создаём родительские директории
parent_dir="$(dirname -- "$target_path")"
mkdir -p -- "$parent_dir"

# 5) создаём файл, если его нет
[[ -e "$target_path" ]] || : >"$target_path"

# 6) открываем в редакторе
editor="${EDITOR:-nvim}"
exec "$editor" -- "$target_path"
