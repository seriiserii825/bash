source /home/serii/Documents/bash-wp/functions/acf-functions.sh

function selectPage(){
  local pages_json=$(wp post list --post_type=page --format=json)
  local pages=($(echo $pages_json | jq -r '.[] | .post_title'))
  local pages_slug=($(echo $pages_json | jq -r '.[] | .post_name'))
  local pages_ids=($(echo $pages_json | jq -r '.[] | .ID'))
 COLUMNS=1
  select page in "${pages_slug[@]}"; do
    [[ $page ]] || continue
    local page_id=$(echo $pages_json | jq -r '.[] | select(.post_name == "'${page}'") | .ID')
    echo "{
    \"param\": \"page\",
    \"operator\": \"==\",
    \"value\": \"${page_id}\"
    }"
  break
done
}

function selectPostType(){
 local post_types_json=$(wp post-type list --publicly_queryable=1 --fields=name --format=json)
 local names=($(echo $post_types_json | jq -r '.[] | .name'))
 COLUMNS=1
 select name in "${names[@]}"; do
   [[ $name ]] || continue
   echo "{
   \"param\": \"post_type\",
   \"operator\": \"==\",
   \"value\": \"${name}\"
   }"
  break
done
}

function selectTaxonomy(){
  local taxonomies_json=$(wp taxonomy list --fields=name --format=json)
 local names=($(echo $taxonomies_json | jq -r '.[] | .name'))
 COLUMNS=1
 select name in "${names[@]}"; do
   [[ $name ]] || continue
   echo "{
   \"param\": \"taxonomy\",
   \"operator\": \"==\",
   \"value\": \"${name}\"
   }"
  break
done
}

function chooseType(){
  select type in "page" "post_type" "taxonomy"; do
    [[ $type ]] || continue
    case $type in
      "page")
        selectPage
        break
        ;;
      "post_type")
        selectPostType
        break
        ;;
      "taxonomy")
        selectTaxonomy
        break
        ;;
    esac
    break
  done
}

function newSection(){
  local setting=$(chooseType)

  local id_upper="$(openssl rand -base64 12)"
  local id="$(echo $id_upper | tr '[:upper:]' '[:lower:]')"
  local tab_id_upper="$(openssl rand -base64 12)"
  local tab_id="$(echo $tab_id_upper | tr '[:upper:]' '[:lower:]')"
  local group_id_upper="$(openssl rand -base64 12)"
  local group_id="$(echo $group_id_upper | tr '[:upper:]' '[:lower:]')"
  read -p "Enter the name of the section: " section_input
  local slug=$(echo $section_input | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  cat <<TEST >> "acf/$slug.json"
[
    {
        "ID": false,
        "key": "group_${id}",
        "title": "${section_input}",
        "fields": [
            {
                "key": "field_${tab_id}",
                "label": "Test",
                "name": "",
                "aria-label": "",
                "type": "tab",
                "instructions": "",
                "required": 0,
                "conditional_logic": 0,
                "wrapper": {
                    "width": "",
                    "class": "",
                    "id": ""
                  },
                "placement": "top",
                "endpoint": 0
              },
            {
                "key": "field_${group_id}",
                "label": "Test",
                "name": "test",
                "aria-label": "",
                "type": "group",
                "instructions": "",
                "required": 0,
                "conditional_logic": 0,
                "wrapper": {
                    "width": "",
                    "class": "",
                    "id": ""
                  },
                "layout": "block",
                "sub_fields": []
              }
        ],
        "location": [
            [
                ${setting}
            ]
        ],
        "menu_order": 0,
        "position": "normal",
        "style": "default",
        "label_placement": "top",
        "instruction_placement": "label",
        "hide_on_screen": "",
        "active": true,
        "description": "",
        "show_in_rest": 0,
        "_valid": true
      }
]
TEST
wpImport
wpExport
exit 0
}
