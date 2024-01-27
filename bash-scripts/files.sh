#! /bin/bash


  select action in FindFiles RemoveFiles; do
    case $action in
      FindFiles)
        read -p "Enter file name: " file_name
        find . -type f -name "$file_name"
        ;;
      RemoveFiles)
        read -p "Enter file name: " file_name
        find . -type f -name "$file_name" -delete
        echo "All files with name $file_name were deleted"
        break;
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
