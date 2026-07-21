#!/bin/bash
# Archives/unarchives a fzf-selected folder or file as tar with progress, or views a tar's contents

if ! command -v pv >/dev/null 2>&1; then
  echo "pv not found, installing via pacman..."
  sudo pacman -Sy --noconfirm pv
fi

select action in "archive" "unarchive" "view"; do
  case $action in
    archive)
      target=$(find . -maxdepth 1 -mindepth 1 | fzf)
      if [[ -z $target ]]; then
        echo "No file selected"
        exit 1
      fi
      archive_name="$(basename "$target").tar"
      tar -cf - "$target" | pv > "$archive_name"
      echo "Created $archive_name"
      break
      ;;
    unarchive)
      archive_path=$(find . -maxdepth 1 -type f -name "*.tar" | fzf)
      if [[ -z $archive_path ]]; then
        echo "No archive selected"
        exit 1
      fi
      pv "$archive_path" | tar -xf -
      break
      ;;
    view)
      archive_path=$(find . -maxdepth 1 -type f -name "*.tar" | fzf)
      if [[ -z $archive_path ]]; then
        echo "No archive selected"
        exit 1
      fi
      tar -tf "$archive_path"
      break
      ;;
  esac
done
