#!/bin/bash
# Angular project helper: create icon, component, page, layout

tgreen='\e[32m'
tmagenta='\e[35m'
treset='\e[0m'

function checkNg(){
  if ! [ -x "$(command -v ng)" ]; then
    echo -e "${tmagenta}Angular CLI (ng) is not installed. Installing...${treset}"

    if ! [ -x "$(command -v npm)" ]; then
      echo -e "${tmagenta}Error: npm is not installed.${treset}"
      exit 1
    fi

    npm install -g @angular/cli

    if ! [ -x "$(command -v ng)" ]; then
      echo -e "${tmagenta}Error: failed to install Angular CLI (ng).${treset}"
      exit 1
    fi

    echo -e "${tgreen}Angular CLI (ng) installed successfully.${treset}"
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

function readKebabPath(){
  local label=$1
  local path

  read -p "$label (kebab-case, e.g. manager or apps/manager): " path

  if [ -z "$path" ]; then
    echo -e "${tmagenta}Error: name is required.${treset}"
    exit 1
  fi

  path="${path#/}"
  path="${path%/}"

  if ! [[ "$path" =~ ^[a-z0-9]+(-[a-z0-9]+)*(/[a-z0-9]+(-[a-z0-9]+)*)*$ ]]; then
    echo -e "${tmagenta}Error: path must be kebab-case segments separated by / (e.g. apps/manager).${treset}"
    exit 1
  fi

  echo "$path"
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

function listTopLevel(){
  local dir=$1

  if [ -d "$dir" ]; then
    echo -e "${tgreen}Existing in ${dir}/:${treset}"
    ls -1 "$dir"
    echo ""
  fi
}

function createComponent(){
  checkNg
  listTopLevel "src/app/components"
  local path=$(readKebabPath "Component path")
  local dir="${path%/*}"
  local name="${path##*/}"

  if [ "$dir" == "$path" ]; then
    dir=""
  fi

  local target
  if [ -n "$dir" ]; then
    target="components/${dir}/${name}"
  else
    target="components/${name}"
  fi

  ng generate component "$target" --skip-tests --style=none
  echo -e "${tgreen}Component ${target} created${treset}"
}

function createPage(){
  checkNg
  listTopLevel "src/app/pages"
  local path=$(readKebabPath "Page path")
  local dir="${path%/*}"
  local name="${path##*/}"

  if [ "$dir" == "$path" ]; then
    dir=""
  fi

  local target
  if [ -n "$dir" ]; then
    target="pages/${dir}/${name}-page"
  else
    target="pages/${name}-page"
  fi

  ng generate component "$target" --skip-tests --style=none
  echo -e "${tgreen}Page ${target} created${treset}"
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
  echo -e "${tgreen}2. Create component (supports nested paths, e.g. form/input)${treset}"
  echo -e "${tgreen}3. Create page (supports nested paths, e.g. apps/manager)${treset}"
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
