#! /bin/bash

echo "${tgreen}Init: In existing project${treset}"
echo "${tblue}Install: Install venv${treset}"
echo "${tgreen}New project: Create new project with folder name${treset}"
echo "${tblue}Update: after git clone or git pull to update all packages${treset}"

COLUMNS=1
select action in "${tgreen}Install Poetry${treset}" "${tblue}New project${treset}" "${tyellow}Init${treset}" "${tgreen}Install${treset}" "${tblue}Update${treset}" "${tyellow}Add${treset}" "${tgreen}Add Dev${treset}" "${tblue}Gitignore${treset}" "${tmagenta}Exit${treset}"
do
  case $action in
    "${tgreen}Install Poetry${treset}")
      sudo apt install python3-poetry -y
      ;;
    "${tblue}New project${treset}")
      echo "Enter project name: "
      read project
      poetry new $project
      ;;
    "${tyellow}Init${treset}")
      poetry init
      ;;
    "${tgreen}Install${treset}")
      poetry install
      ;;
    "${tblue}Update${treset}")
      poetry update
      ;;
    "${tyellow}Add${treset}")
      echo "Enter package name: "
      read package
      poetry add $package
      ;;
    "${tgreen}Add Dev${treset}")
      echo "Enter package name: "
      read package
      poetry add --dev $package
      ;;
    "${tblue}Gitignore${treset}")
      echo ".venv" >> .gitignore
      echo "*cache*" >> .gitignore
      ;;
    "${tmagenta}Exit${treset}")
      break
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done
