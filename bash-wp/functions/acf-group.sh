source /home/serii/Documents/bash-wp/functions/acf-functions.sh

function showGroups(){
  local file_path=$1
  my_array=($(getGroupsLabels $file_path))
  for label in "${my_array[@]}"; do
    echo "${tgreen}$label${treset}"
  done
}

function editGroup(){
  local file_path=$1
  labels=($(getGroupsLabels $file_path))

  COLUMNS=1
  select elem in "${labels[@]}"; do 
    [[ $elem ]] || continue
    local key_group=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "group") | .key' $file_path)
    local group_index=$(jq '.[0].fields | map(.key) | index("'${key_group}'")' $file_path)

    read -p "Enter the name of the group: " group_input

    if [[ $group_input == '' ]]; then
      break
    else
      local group_name=$(echo $group_input | tr ' ' '_')
    fi
    local result=$(cat $file_path | jq '.[0].fields['${group_index}'].label = "'${group_name}'"')
    echo $result > $file_path

    local key_tab=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "tab") | .key' $file_path)
    local tab_index=$(jq '.[0].fields | map(.key) | index("'${key_tab}'")' $file_path)
    local result_tab=$(cat $file_path | jq '.[0].fields['${tab_index}'].label = "'${group_name}'"')
    echo $result_tab > $file_path

    local slug=$(echo $group_name | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    local slug_result=$(cat $file_path | jq '.[0].fields['${group_index}'].name = "'${slug}'"')
    echo $slug_result > $file_path
    wpImport
    break
  done
}


function newGroup(){
  local id="$(openssl rand -base64 12)"
  local name=$(echo $1 | tr ' ' '_')
  local type=$2
  local file_path=$3
  local slug=$(echo $name | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  if [ $type == "tab" ]; then
    local result=$(cat $file_path | jq '.[0].fields[.[0].fields| length] += {
    "key": "field_'${id}'",
    "label": "'${name}'",
    "type": "tab",
    "placement": "top",
    "endpoint": 0,
    "date": "2010-01-07T19:55:99.999Z",
    "xml": "xml_samplesheet_2017_01_07_run_09.xml",
    "status": "OKKK",
    "message": "metadata loaded into iRODS successfullyyyyy"
  }')
  echo $result > $file_path
  elif [ $type == "group" ]; then
  local result=$(cat $file_path | jq '.[0].fields[.[0].fields| length] += {
  "key": "field_'${id}'",
  "label": "'${name}'",
  "name": "'${slug}'",
  "type": "group",
  "instructions": "",
  "required": 0,
  "conditional_logic": 0,
  "wrapper": {
  "width": "",
  "class": "",
  "id": "",
  },
  "layout": "block",
  "sub_fields": [],
  "placement": "top",
  "endpoint": 0,
  "date": "2010-01-07T19:55:99.999Z",
  "xml": "xml_samplesheet_2017_01_07_run_09.xml",
  "status": "OKKK",
  "message": "metadata loaded into iRODS successfullyyyyy"
  }')
  echo $result > $file_path
  fi
  wpImport
}

function removeGroup(){
  local file_path=$1
  local labels=($(getGroupsLabels $file_path))

  COLUMNS=1
  select elem in "${labels[@]}"; do 
    [[ $elem ]] || continue
    local key_tab=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "tab") | .key' $file_path)
    local key_group=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "group") | .key' $file_path)
    local result_tab=$(cat $file_path | jq 'del(.[0].fields[] | select(.key == "'${key_tab}'"))')
    echo $result_tab > $file_path
    local result_group=$(cat $file_path | jq 'del(.[0].fields[] | select(.key == "'${key_group}'"))')
    echo $result_group > $file_path
    wpImport
    break
  done
}
