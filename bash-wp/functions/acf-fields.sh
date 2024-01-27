source /home/serii/Documents/bash-wp/functions/acf-functions.sh

function showFields(){
  local file_path=$1
  labels=($(getGroupsLabels $file_path))
  for label in "${labels[@]}"; do
    local key_group=$(jq -r '.[0].fields[] | select(.label == "'${label}'" and .type == "group") | .key' $file_path)
    local group_index=$(jq '.[0].fields | map(.key) | index("'${key_group}'")' $file_path)
    readarray -t sub_fields < <(jq --compact-output '.[0].fields['${group_index}'].sub_fields[]' $file_path)

    echo "${tblue}$label${treset}"
    for item in "${sub_fields[@]}"; do
      local sub_label=$(jq --raw-output '.label' <<< "$item")
      local sub_type=$(jq --raw-output '.type' <<< "$item")
      local sub_width=$(jq --raw-output '.wrapper.width' <<< "$item")
      if [[ $sub_width == '' ]]; then
        echo "${tgreen}$sub_label: $sub_type${treset}"
      else
        echo "${tgreen}$sub_label: $sub_type${treset} ${tyellow}($sub_width)${treset}"
      fi
    done
  done
}

function addSubField(){
  local file_path=$1
  local id="field_$(openssl rand -base64 12)"
  local labels=($(getGroupsLabels $file_path) "Exit")
  echo "${tblue}Select group:${treset}"
  COLUMNS=1
  select elem in "${labels[@]}"; do 
    if [[ $elem == 'Exit' ]]; then
      break
    fi
    [[ $elem ]] || continue
    read -p "Enter the name of the field: " field_input
    local field_label=$(echo $field_input | tr ' ' '_')
    local fiedl_name=$(echo $field_label | tr ' ' '_')
    local key_group=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "group") | .key' $file_path)
    local group_index=$(jq '.[0].fields | map(.key) | index("'${key_group}'")' $file_path)
    echo "${tmagenta}Select the type of the field${treset}"
    select type in "text" "image" "wysiwyg" "textarea" "gallery" "repeater" "file" "exit"; do
      [[ $type ]] || continue
      break
    done
    echo "${tblue}Select width of field:${treset}"
    echo "${tmagenta}Choose the width of the field${treset}"
    select width in "100" "50" "33" "25" "20"; do
      [[ $width ]] || continue
      break
    done
    if [[ $type == 'image' || $type == 'gallery' || $type == 'file' ]]; then
      local result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields[.[0].fields['${group_index}'].sub_fields| length] += {
      "key": "'${id}'",
      "label": "'${field_label}'",
      "name": "'${field_name}'",
      "aria-label": "",
      "type": "'${type}'",
      "instructions": "",
      "required": 0,
      "conditional_logic": 0,
      "wrapper": {
        "width": "'${width}'",
        "class": "",
        "id": ""
      },
        "default_value": "",
        "maxlength": "",
        "placeholder": "",
        "prepend": "",
        "append": "",
        "return_format": "url",
      }')
      echo $result > $file_path
    elif [[ $type == 'wysiwyg' ]]; then
      local result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields[.[0].fields['${group_index}'].sub_fields| length] += {
      "key": "'${id}'",
      "label": "'${field_label}'",
      "name": "'${field_name}'",
      "aria-label": "",
      "type": "'${type}'",
      "instructions": "",
      "required": 0,
      "conditional_logic": 0,
      "wrapper": {
      "width": "'${width}'",
      "class": "",
      "id": ""
      },
      "default_value": "",
      "maxlength": "",
      "placeholder": "",
      "prepend": "",
      "append": "",
      "toolbar": "basic",
      "media_upload": 0
      }')
      echo $result > $file_path
    elif [[ $type == 'repeater' ]]; then
      local result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields[.[0].fields['${group_index}'].sub_fields| length] += {
      "key": "'${id}'",
      "label": "'${field_label}'",
      "name": "'${field_name}'",
      "aria-label": "",
      "type": "'${type}'",
      "instructions": "",
      "required": 0,
      "conditional_logic": 0,
      "wrapper": {
      "width": "'${width}'",
      "class": "",
      "id": ""
      },
      "default_value": "",
      "maxlength": "",
      "placeholder": "",
      "prepend": "",
      "append": "",
      "layout": "table",
      "button_label": "Add Row",
      "sub_fields": []
      }')
      echo $result > $file_path
    else
      local result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields[.[0].fields['${group_index}'].sub_fields| length] += {
      "key": "'${id}'",
      "label": "'${field_label}'",
      "name": "'${field_name}'",
      "aria-label": "",
      "type": "'${type}'",
      "instructions": "",
      "required": 0,
      "conditional_logic": 0,
      "wrapper": {
      "width": "'${width}'",
      "class": "",
      "id": ""
      },
      "default_value": "",
      "maxlength": "",
      "placeholder": "",
      "prepend": "",
      "append": ""
      }')
      echo $result > $file_path
    fi
    wpImport
  done
}


function editSubField() {
  local file_path=$1
  local labels=($(getGroupsLabels $file_path) "Exit")
  echo "${tblue}Select group:${treset}"
  COLUMNS=1
  select elem in "${labels[@]}"; do 
    if [[ $elem == 'Exit' ]]; then
      break
    fi
    [[ $elem ]] || continue
    local key_group=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "group") | .key' $file_path)
    local group_index=$(jq '.[0].fields | map(.key) | index("'${key_group}'")' $file_path)
    local sub_fields=$(jq --compact-output '.[0].fields['${group_index}'].sub_fields[]' $file_path)
    local sub_fields_labels=()
    for item in "${sub_fields[@]}"; do
      local sub_label=$(jq --raw-output '.label' <<< "$item")
      sub_fields_labels+=($sub_label)
    done
    echo "${tyellow}Select field:${treset}"
    COLUMNS=1
    select field in "${sub_fields_labels[@]}"; do 
      [[ $field ]] || continue
      echo "${tmagenta}Leave empty if you don't want to change the name of the field${treset}"
      read -p "Enter the name of the field: " field_input
      if [[ $field_input == '' ]]; then
        local field_label=$field
      else
        local field_label=$(echo $field_input | tr ' ' '_')
      fi
      local field_name=$(echo $field_label | tr ' ' '_')
      local key_field=$(jq -r '.[0].fields['${group_index}'].sub_fields[] | select(.label == "'${field}'") | .key' $file_path)
      local field_index=$(jq '.[0].fields['${group_index}'].sub_fields | map(.key) | index("'${key_field}'")' $file_path)
      local label_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].label = "'${field_label}'"')
      echo $label_result > $file_path
      local name_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].name = "'${field_name}'"')
      echo $name_result > $file_path
      echo "${tblue}Select type of field:${treset}"
      echo "${tmagenta}Choose exit if you don't want to change the type of the field${treset}"
      select type in "text" "image" "wysiwyg" "textarea" "gallery" "exit"; do
        [[ $type ]] || continue
        if [[ $type == 'exit' ]]; then
          break
        fi
        local type_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].type = "'${type}'"')
        echo $type_result > $file_path
        if [[ $type == 'image' || $type == 'gallery' ]]; then
          local return_format_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].return_format = "url"')
          echo $return_format_result > $file_path
        fi
        if [[ $type == 'wysiwyg' ]]; then
          local toolbar_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].toolbar = "basic"')
          echo $toolbar_result > $file_path
          local media_upload_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].media_upload = 0')
          echo $media_upload_result > $file_path
        fi
        break
      done
      echo "${tblue}Select width of field:${treset}"
      echo "${tmagenta}Choose exit if you don't want to change the width of the field${treset}"
      select width in "100" "50" "33" "25" "20" "exit"; do
        [[ $width ]] || continue
        if [[ $width == 'exit' ]]; then
          break
        fi
        local width_result=$(cat $file_path | jq '.[0].fields['${group_index}'].sub_fields['${field_index}'].wrapper.width = "'${width}'"')
        echo $width_result > $file_path
        break
      done
      wpImport
      break
    done
  done
}

function removeField(){
  local file_path=$1
  local labels=($(getGroupsLabels $file_path) "Exit")
  echo "${tblue}Select group:${treset}"
  COLUMNS=1
  select elem in "${labels[@]}"; do 
    if [[ $elem == 'Exit' ]]; then
      break
    fi
    [[ $elem ]] || continue
    local key_group=$(jq -r '.[0].fields[] | select(.label == "'${elem}'" and .type == "group") | .key' $file_path)
    local group_index=$(jq '.[0].fields | map(.key) | index("'${key_group}'")' $file_path)
    local sub_fields=$(jq --compact-output '.[0].fields['${group_index}'].sub_fields[]' $file_path)
    local sub_fields_labels=()
    for item in "${sub_fields[@]}"; do
      local sub_label=$(jq --raw-output '.label' <<< "$item")
      sub_fields_labels+=($sub_label)
    done
    echo "${tyellow}Select field:${treset}"
    COLUMNS=1
    select field in "${sub_fields_labels[@]}"; do 
      [[ $field ]] || continue
      local key_field=$(jq -r '.[0].fields['${group_index}'].sub_fields[] | select(.label == "'${field}'") | .key' $file_path)
      local field_index=$(jq '.[0].fields['${group_index}'].sub_fields | map(.key) | index("'${key_field}'")' $file_path)
      local result=$(cat $file_path | jq 'del(.[0].fields['${group_index}'].sub_fields['${field_index}'])')
      echo $result > $file_path
      break
    done
    wpImport
  done
}

