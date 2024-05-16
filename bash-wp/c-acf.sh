#!/bin/bash

source /home/serii/Documents/bash-wp/functions/acf-group.sh
source /home/serii/Documents/bash-wp/functions/acf-fields.sh
source /home/serii/Documents/bash-wp/functions/acf-section.sh

if [ ! -f "front-page.php" ]
then
  echo "${tmagenta}front-page.php not found, it's not a wordpress template${treset}"
  exit 1
fi

# file_path=acf/page-home.json
select action in "New section" "Continue"
do
  case $action in
    "New section")
      newSection
      break
      ;;
    "Continue")
      echo "Continue"
      break
      ;;
  esac
done

cd acf/

json_file=$(fzf)

file_path="acf/$json_file"

cd ..

if [[ "$file_path" != *"json"* ]]; then
  echo "${tmagenta}File is not json${treset}"
  exit 1
fi

COLUMNS=1
select action in "${tgreen}AddGroup${treset}" "${tgreen}AddField${treset}" "${tblue}EditGroup${treset}" "${tblue}EditField${treset}" "${tyellow}ShowGroups${treset}" "${tyellow}ShowFields${treset}" "${tmagenta}RemoveGroup${treset}" "${tmagenta}RemoveField${treset}" "${tmagenta}Exit${treset}"
do
  case $action in
    "${tgreen}AddGroup${treset}")
      read -p "Enter the name of the group: " group_name
      newGroup "$group_name" "tab" $file_path
      newGroup "$group_name" "group" $file_path
      ;;
    "${tblue}EditGroup${treset}")
      editGroup $file_path
      ;;
    "${tyellow}ShowGroups${treset}")
      showGroups $file_path
      ;;
    "${tmagenta}RemoveGroup${treset}")
      removeGroup $file_path
      ;;
    "${tgreen}AddField${treset}")
      addSubField $file_path
      ;;
    "${tblue}EditField${treset}")
      editSubField $file_path
      ;;
    "${tyellow}ShowFields${treset}")
      showFields $file_path
      ;;
    "${tmagenta}RemoveField${treset}")
      removeField $file_path
      ;;
    "${tmagenta}Exit${treset}")
      echo "Exit"
      break
      ;;
  esac
done

