#!/bin/bash
# Zips a fzf-selected folder or unzips a fzf-selected archive, removes original after

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

current_dir=$(pwd)
folder_name=$(basename "$current_dir")
downloads_dir="$HOME/Downloads"

select actin in "zip" "unzip" "zip_all_by_parent_folder_name"; do
  case $actin in
    zip)
      files=$(find . -maxdepth 1 -mindepth 1 | fzf_multiselect)
      if [[ -z $files ]]; then
        echo "No file selected"
        exit 1
      fi
      read -p "Enter archive name: " folder_name
      if [[ -z $folder_name ]]; then
        echo "No archive name entered"
        exit 1
      fi
      mapfile -t files_array <<< "$files"
      zip -r "$folder_name.zip" "${files_array[@]}"
      break
      ;;
    unzip)
      zip_path=$(fzf)
      unzip $zip_path
      rm $zip_path
      break
      ;;
    zip_all_by_parent_folder_name)
      archive_name="${folder_name}.zip"
      echo "Archive: $archive_name → $downloads_dir"
      read -r -p "Continue? [y/N] " confirm
      [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
      cd "$(dirname "$current_dir")" && zip -r "$downloads_dir/$archive_name" "$folder_name"
      if [[ $? -ne 0 ]]; then
        echo "Failed to create archive."
        exit 1
      fi
      echo "Archived and moved to $downloads_dir/$archive_name"
      break
      ;;
  esac
done
