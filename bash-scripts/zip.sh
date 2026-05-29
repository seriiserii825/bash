#!/bin/bash
# Zips a fzf-selected folder or unzips a fzf-selected archive, removes original after

select actin in "zip" "unzip"; do
  case $actin in
    zip)
      folder_path=$(find . -maxdepth 1 -type d | fzf)
      zip -r $folder_path.zip $folder_path
      rm -r $folder_path
      break
      ;;
    unzip)
      zip_path=$(fzf)
      unzip $zip_path
      rm $zip_path
      break
      ;;
  esac
done
