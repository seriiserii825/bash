#!/bin/bash

function wpImport(){
  wp acf clean
  wp acf import --all
}


function wpExport(){
  rm -rf acf
  wp acf export --all
}

function getGroupsLabels(){
  local file_path=$1
  local labels=()
  # read each item in the JSON array to an item in the Bash array
  readarray -t my_array < <(jq --compact-output '.[0].fields[]' $file_path)

  for item in "${my_array[@]}"; do
    local label=$(jq --raw-output '.label' <<< "$item")
    local type=$(jq --raw-output '.type' <<< "$item")
    if [ $type == "group" ]; then
      labels+=($label)
    fi
  done
  echo "${labels[@]}"
}




