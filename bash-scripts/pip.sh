#! /bin/bash

if [ ! -f requirements.txt ]; then
  touch requirements.txt
fi

select action in "Install Package" "Install all" "Uninstall" "Freeze" "Exit"; do
  case $action in
    "Install Package")
      read -p "Enter the package name: " package_name
      pip install $package_name
      pip freeze > requirements.txt
      ;;
    "Install all")
      pip install -r requirements.txt
      ;;
    "Uninstall")
      read -p "Enter the package name: " package_name
      pip uninstall $package_name
      pip freeze > requirements.txt
      ;;
    "Freeze")
      pip freeze > requirements.txt
      ;;
    "Exit")
      break
      exit
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done

read -p "Enter the package name: " package_name

