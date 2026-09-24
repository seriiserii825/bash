#!/bin/bash
# Angular project helper: create icon, component, page, layout

tgreen='\e[32m'
tmagenta='\e[35m'
treset='\e[0m'

function goToProjectRoot(){
  local dir="$PWD"

  while [ "$dir" != "/" ]; do
    if [ -f "$dir/angular.json" ]; then
      cd "$dir" || exit 1
      return
    fi
    dir=$(dirname "$dir")
  done

  echo -e "${tmagenta}Error: angular.json not found (not inside an Angular project).${treset}"
  exit 1
}

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

function chooseOrCreateDirectory(){
  local base=$1

  mkdir -p "$base"

  local need_folder
  need_folder=$(printf "No, create in root\nYes, choose or create a folder\nExit" | fzf --prompt="Use a subfolder? > " --height=6 --no-info)

  if [ -z "$need_folder" ] || [ "$need_folder" == "Exit" ]; then
    echo -e "${tmagenta}Exiting.${treset}" >&2
    exit 0
  fi

  if [ "$need_folder" == "No, create in root" ]; then
    echo ""
    return
  fi

  local dirs
  dirs=$(find "$base" -mindepth 1 -type d | sed "s|^${base}/||" | sort)

  local options="+ Create new folder"
  if [ -n "$dirs" ]; then
    options="${options}"$'\n'"${dirs}"
  fi
  options="${options}"$'\n'"Exit"

  local choice
  choice=$(printf '%s\n' "$options" | fzf --prompt="Directory > " --height=40% --reverse)

  if [ -z "$choice" ] || [ "$choice" == "Exit" ]; then
    echo -e "${tmagenta}Exiting.${treset}" >&2
    exit 0
  fi

  if [ "$choice" == "+ Create new folder" ]; then
    local parent_options="."
    if [ -n "$dirs" ]; then
      parent_options="${parent_options}"$'\n'"${dirs}"
    fi
    parent_options="${parent_options}"$'\n'"Exit"

    local parent
    parent=$(printf '%s\n' "$parent_options" | fzf --prompt="Parent for new folder > " --height=40% --reverse)

    if [ -z "$parent" ] || [ "$parent" == "Exit" ]; then
      echo -e "${tmagenta}Exiting.${treset}" >&2
      exit 0
    fi

    local new_name
    new_name=$(readKebabName "New folder name")

    if [ "$parent" == "." ]; then
      echo "$new_name"
    else
      echo "${parent}/${new_name}"
    fi
  else
    echo "$choice"
  fi
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

  listTopLevel "src/app/icons"
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

function _treeDir(){
  local dir=$1
  local prefix=$2

  local items=()
  while IFS= read -r item; do
    [ -d "$dir/$item" ] && items+=("$item")
  done < <(ls -1 "$dir" 2>/dev/null)

  local total=${#items[@]}
  for ((i=0; i<total; i++)); do
    local item="${items[$i]}"
    if [ $((i + 1)) -eq $total ]; then
      echo "${prefix}└── ${item}"
      _treeDir "$dir/$item" "${prefix}    "
    else
      echo "${prefix}├── ${item}"
      _treeDir "$dir/$item" "${prefix}│   "
    fi
  done
}

function listTopLevel(){
  local dir=$1

  if [ -d "$dir" ]; then
    echo -e "${tgreen}Existing in ${dir}/:${treset}"
    if command -v tree &>/dev/null; then
      tree -d --noreport "$dir" | tail -n +2
    else
      _treeDir "$dir" ""
    fi
    echo ""
  fi
}

function createNested(){
  local folder=$1
  local suffix=$2
  local label=$3

  checkNg

  listTopLevel "src/app/${folder}"

  local dir_path
  dir_path=$(chooseOrCreateDirectory "src/app/${folder}")

  local entity_name
  entity_name=$(readKebabName "${label} name")

  local target
  if [ -z "$dir_path" ]; then
    target="${folder}/${entity_name}${suffix}"
  else
    target="${folder}/${dir_path}/${entity_name}${suffix}"
  fi

  ng generate component "$target" --skip-tests --style=none --flat
  echo -e "${tgreen}${label} ${target} created${treset}"
}

function createComponent(){
  createNested "components" "" "Component"
}

function createPage(){
  createNested "pages" "-page" "Page"
}

function createLayout(){
  createNested "layouts" "-layout" "Layout"
}

function createShared(){
  createNested "shared" "-shared" "Shared"
}

function menu(){
  goToProjectRoot

  echo -e "${tgreen}1. Create icon${treset}"
  echo -e "${tgreen}2. Create component (supports nested paths, e.g. form/input)${treset}"
  echo -e "${tgreen}3. Create page (supports nested paths, e.g. apps/manager)${treset}"
  echo -e "${tgreen}4. Create layout (supports nested paths, e.g. admin/main)${treset}"
  echo -e "${tgreen}5. Create shared (supports nested paths, e.g. ui/button)${treset}"
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
