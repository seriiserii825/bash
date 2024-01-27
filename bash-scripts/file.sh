#! /bin/bash

file_path=$( fzf )
abs_path=$( realpath $file_path )
echo "File path is: $file_path"
COLUMNS=1
select action in Delete DeleteAllExceptThis Rename Read CopyName CopyPath CopyAbsPath CopyToDownloads FileToBuffer BufferToFile Execute OpenInBrowser ToTemplatePart Quit; do
  case $action in
    Delete)
      rm $file_path
      echo "${tgreen}File $file_path was deleted${treset}"
      break
      ;;
    DeleteAllExceptThis)
      find -type f -not -name "$file" -delete
      echo "${tgreen}All files except $file were deleted${treset}"
      break
      ;;
    Rename)
      read -p "Enter new file name: " new_file_name
      echo "file path is: $file_path"
      dir_path=$(dirname $file_path)
      echo "dir path is: $dir_path"
      mv $file_path $dir_path/$new_file_name
      echo "${tgreen}File $file_path was renamed to $dir_path/$new_file_name${treset}"
      exit 0
      ;;
    Read)
      bat $file_path
      ;;
    CopyName)
      echo $file_path | awk 'BEGIN{FS="/"}{print $NF}' | tr -d '\n' | xsel -b -i
      echo "${tgreen}File name was copied to clipboard${treset}"
      break
      ;;
    CopyPath)
      echo $file_path | tr -d '\n' | xsel -b -i
      echo "${tgreen}File path was copied to clipboard${treset}"
      break
      ;;
    CopyAbsPath)
      echo $abs_path | tr -d '\n' | xsel -b -i
      echo "${tgreen}File absolute path was copied to clipboard${treset}"
      break
      ;;
    CopyToDownloads)
      cp $file_path ~/Downloads
      break
      ;;
    Execute)
      chmod +x $file_path
      echo "${tgreen}Execute permission was added to $file_path${treset}"
      break
      ;;
    FileToBuffer)
      cat $file_path | tr -d '\n' | xsel -b -i
      echo "${tgreen}File was copied to clipboard${treset}"
      ;;
    BufferToFile)
      clipboard=$(xclip -o -selection clipboard)
      echo $clipboard > $file_path
      bat $file_path
      ;;
    OpenInBrowser)
      vivaldi $file_path
      break
      ;;
    ToTemplatePart)
      filepath=$file_path
      filename=$(basename "$filepath")
      filename_no_ext="${filename%.*}"
      file_path_without_extension="${filepath%.*}"
      template_part="<?php echo get_template_part( '$file_path_without_extension'); ?>"
      echo $template_part | tr -d '\n' | xsel -b -i
      break
      ;;
    Quit)
      break
      ;;
    *)
      echo "ERROR! Please select between 1..3"
      ;;
  esac
done
