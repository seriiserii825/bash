#! /bin/bash

function init(){
  current_dir=$(pwd)
  python3 -m venv venv
  source venv/bin/activate
  python3 -m pip install --upgrade pip
}

function activate(){
  source venv/bin/activate
}

function initIfNotExists(){
  if [ ! -d "venv" ]; then
    init
  else
    activate
  fi
}

function menu(){
  echo "${tgreen}1. List${treset}"
  echo "${tblue}2. Install Package${treset}"
  echo "${tblue}3. Install all${treset}"
  echo "${tmagenta}4. Uninstall${treset}"
  echo "${tmagenta}5. Reinstall all${treset}"
  echo "${tmagenta}6. Exit${treset}"

  read -p "Enter the option: " option
  case $option in
    1)
      initIfNotExists
      bat requirements.txt
      deactivate
      menu
      ;;
    2)
      read -p "Enter the package name: " package_name
      initIfNotExists
      python3 -m pip install $package_name
      pip freeze > requirements.txt
      deactivate
      menu
      ;;
    3)
      initIfNotExists
      python3 -m pip install -r requirements.txt
      deactivate
      menu
      ;;
    4)
      initIfNotExists
      # package name from file requirements.txt with fzf
      package_name=$(cat requirements.txt | fzf)
      package_name=$(echo $package_name | cut -d'=' -f1)
      python3 -m pip uninstall $package_name
      pip freeze > requirements.txt
      deactivate
      menu
      ;;
    5)
      rm -rf venv
      initIfNotExists
      python3 -m pip install -r requirements.txt
      deactivate
      menu
      ;;
    6)
      exit 0
      ;;
    *)
      echo "Invalid option"
      exit 0
      ;;
  esac
}

menu
