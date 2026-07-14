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

  if ! [ -x "$(command -v xclip)" ]; then
    echo -e "${tmagenta}Error: xclip is not installed.${treset}"
    exit 1
  fi

  local svg
  svg=$(xclip -o -selection clipboard 2>/dev/null)

  if ! printf '%s' "$svg" | grep -qi '<svg[[:space:]>]'; then
    echo -e "${tmagenta}Error: clipboard does not contain an SVG.${treset}"
    exit 1
  fi

  if printf '%s' "$svg" | grep -qi 'fill="'; then
    svg=$(printf '%s' "$svg" | perl -0777 -pe 's/fill="(?!none")[^"]*"/fill="currentColor"/gi')
  else
    svg=$(printf '%s' "$svg" | perl -0777 -pe 's/<svg(\s)/<svg fill="currentColor"$1/i')
  fi

  local name=$(readKebabName "Icon name")
  ng generate component "icons/${name}-icon" --skip-tests --style=none

  local html_file
  html_file=$(find "icons/${name}-icon" -maxdepth 1 -name "*.html" | head -1)

  if [ -z "$html_file" ]; then
    echo -e "${tmagenta}Error: generated html file not found.${treset}"
    exit 1
  fi

  printf '%s\n' "$svg" > "$html_file"

  echo -e "${tgreen}Icon component icons/${name}-icon created${treset}"
}

function createComponent(){
  checkNg
  local name=$(readKebabName "Component name")
  ng generate component "components/${name}" --skip-tests --style=none
  echo -e "${tgreen}Component components/${name} created${treset}"
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

function createShared(){
  checkNg
  local name=$(readKebabName "Shared name")
  ng generate component "shared/${name}-shared" --skip-tests --style=none
  echo -e "${tgreen}Shared component shared/${name}-shared created${treset}"
}

function menu(){
  echo -e "${tgreen}1. Create icon${treset}"
  echo -e "${tgreen}2. Create component${treset}"
  echo -e "${tgreen}3. Create page${treset}"
  echo -e "${tgreen}4. Create layout${treset}"
  echo -e "${tgreen}5. Create shared${treset}"
  echo -e "${tmagenta}6. Exit${treset}"

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
    createShared
  elif [ "$option" == "6" ]; then
    exit 0
  else
    echo -e "${tmagenta}Error: option not found.${treset}"
    exit 1
  fi
}

menu
