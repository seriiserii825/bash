#!/bin/bash
# Angular project helper: create icon, component, page, layout

tgreen='\e[32m'
tmagenta='\e[35m'
treset='\e[0m'

function checkNg(){
  if ! [ -x "$(command -v ng)" ]; then
    echo -e "${tmagenta}Error: Angular CLI (ng) is not installed.${treset}"
    exit 1
  fi
}

function readKebabName(){
  local label=$1
  local name

  read -p "$label (kebab-case): " name

  if [ -z "$name" ]; then
    echo -e "${tmagenta}Error: name is required.${treset}"
    exit 1
  fi

  if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo -e "${tmagenta}Error: name must be kebab-case (e.g. arrow-left).${treset}"
    exit 1
  fi

  echo "$name"
}

function createIcon(){
  checkNg
  local name=$(readKebabName "Icon name")
  ng generate component "icons/$name" --skip-tests --style=none
  echo -e "${tgreen}Icon component icons/$name created${treset}"
}

function createComponent(){
  checkNg
  local name=$(readKebabName "Component name")
  ng generate component "components/${name}-component" --skip-tests --style=none
  echo -e "${tgreen}Component components/${name}-component created${treset}"
}

function createPage(){
  checkNg
  local name=$(readKebabName "Page name")
  ng generate component "pages/${name}-page" --skip-tests --style=none
  echo -e "${tgreen}Page pages/${name}-page created${treset}"
}

function createLayout(){
  checkNg
  local name=$(readKebabName "Layout name")
  ng generate component "layouts/${name}-layout" --skip-tests --style=none
  echo -e "${tgreen}Layout layouts/${name}-layout created${treset}"
}

function menu(){
  echo -e "${tgreen}1. Create icon${treset}"
  echo -e "${tgreen}2. Create component${treset}"
  echo -e "${tgreen}3. Create page${treset}"
  echo -e "${tgreen}4. Create layout${treset}"
  echo -e "${tmagenta}5. Exit${treset}"

  read -p "Choose option: " option

  if [ "$option" == "1" ]; then
    createIcon
  elif [ "$option" == "2" ]; then
    createComponent
  elif [ "$option" == "3" ]; then
    createPage
  elif [ "$option" == "4" ]; then
    createLayout
  elif [ "$option" == "5" ]; then
    exit 0
  else
    echo -e "${tmagenta}Error: option not found.${treset}"
    exit 1
  fi
}

menu
