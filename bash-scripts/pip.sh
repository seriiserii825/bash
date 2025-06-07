#! /bin/bash

function installBasePackages(){
  packages=("autopep8" "flake8" "mypy")
  for package in "${packages[@]}"; do
    if ! python3 -m pip show $package > /dev/null 2>&1; then
      installPackageByName $package
    fi
  done
}
function init(){
  current_dir=$(pwd)
  python3 -m venv venv
  source venv/bin/activate
  python3 -m pip install --upgrade pip
}
function activate(){
  source venv/bin/activate
  python3 -m ensurepip --upgrade
  python3 -m pip install --upgrade pip
}
function initIfNotExists(){
  if [ ! -d "venv" ]; then
    init
  else
    activate
  fi
}
function listRequirements(){
  initIfNotExists
  if [ ! -f "requirements.txt" ]; then
    echo "No requirements.txt found"
  fi
  bat requirements.txt
  deactivate
}
function installPackageByName(){
  if [ -n "$1" ]; then
    package_name=$1
  else
    read -p "Enter the package name: " package_name
  fi
  initIfNotExists
  python3 -m pip install $package_name
  pip freeze > requirements.txt
  deactivate
}
function installAllFromRequirements(){
  initIfNotExists
  python3 -m pip install -r requirements.txt
  deactivate
}
function uninstallPackage(){
  initIfNotExists
  package_name=$(cat requirements.txt | fzf)
  package_name=$(echo $package_name | cut -d'=' -f1)
  python3 -m pip uninstall $package_name
  pip freeze > requirements.txt
  deactivate
}
function reinstallAll(){
      rm -rf venv
      initIfNotExists
      python3 -m pip install -r requirements.txt
      deactivate
}
function menu(){
  echo "${tgreen}1. List${treset}"
  echo "${tgreen}1.1 Install Base Modules(mypy, pypen8, flake8)${treset}"
  echo "${tblue}2. Install Package by name${treset}"
  echo "${tblue}3. Install all from requirements.txt${treset}"
  echo "${tmagenta}4. Uninstall${treset}"
  echo "${tmagenta}5. Reinstall all${treset}"
  echo "${tmagenta}6. Exit${treset}"
  read -p "Enter the option: " option
  case $option in
    1)
      listRequirements
      menu
      ;;
    1.1)
      installBasePackages
      menu
      ;;
    2)
      installPackageByName
      menu
      ;;
    3)
      installAllFromRequirements
      menu
      ;;
    4)
      uninstallPackage
      menu
      ;;
    5)
      reinstallAll
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
