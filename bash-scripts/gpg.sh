#!/bin/bash

select actin in "Encrypt" "Decrypt" "Exit"
do
    case $actin in
        "Encrypt")
          file_path=$(fzf)
          read -p "Enter user id:" user_id
          gpg -e -r $user_id $file_path
          rm $file_path
            ;;
        "Decrypt")
          file_path=$(fzf)
          gpg $file_path
          rm $file_path
            ;;
        "Exit")
          break
            ;;
          
    esac
done
