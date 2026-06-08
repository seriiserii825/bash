#!/bin/bash
# Docker manager: images and containers

source /home/serii/dotfiles/zsh_modules/zsh_colors
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

C_IMAGE=$tcyan
C_CONTAINER=$tyellow
C_RESET=$treset

function removeImages() {
  image_list=$(docker images --format "{{.ID}} {{.Repository}} {{.Tag}}")
  echo "$image_list" | nl

  read -rp "Enter the index of the image to remove (comma separated for multiple): " indexes

  IFS=',' read -ra index_array <<< "$indexes"

  for index in "${index_array[@]}"; do
    image_id=$(echo "$image_list" | sed -n "${index}p" | awk '{print $1}')
    if [ -n "$image_id" ]; then
      used_by=$(docker ps -a --filter "ancestor=$image_id" --format "{{.ID}}")
      if [ -n "$used_by" ]; then
        echo "⚠️  Image $image_id is used by container(s): $used_by"
      fi
      docker rmi "$image_id"
    else
      echo "Invalid index: $index"
    fi
  done
}

function findPort() {
  read -rp "Enter port to search: " port
  docker ps --format "table {{.Names}}\t{{.Ports}}" | grep "$port"
}

function showAutostart() {
  docker ps -a --format '{{.Names}}' \
    | xargs docker inspect --format '{{.Name}} -> {{.HostConfig.RestartPolicy.Name}}'
}

function setAutostartNo() {
  selected=$(docker ps -a --format '{{.Names}}' \
    | fzf_multiselect --prompt="Disable autostart: ")
  [ -z "$selected" ] && echo "No containers selected." && return
  echo "$selected" | xargs docker update --restart=no
}

function stopContainers() {
  selected=$(docker ps -a --format '{{.Names}}' \
    | fzf_multiselect --prompt="Stop containers: ")
  [ -z "$selected" ] && echo "No containers selected." && return
  echo "$selected" | xargs docker stop
}

function deleteContainers() {
  selected=$(docker ps -a --format '{{.Names}}' \
    | fzf_multiselect --prompt="Delete containers: ")
  [ -z "$selected" ] && echo "No containers selected." && return
  echo "$selected" | xargs docker rm -f
}

while true; do
  echo ""
  echo "${C_CONTAINER}--- Containers ---${C_RESET}"
  echo "${tgreen}1) Show all containers${C_RESET}"
  echo "${tgreen}2) Find containers with autostart${C_RESET}"
  echo "${tgreen}3) Find port${C_RESET}"
  echo "${tblue}4) Set autostart=no (multi-select)${C_RESET}"
  echo "${tblue}5) Stop containers (multi-select)${C_RESET}"
  echo "${tred}6) Delete containers (multi-select)${C_RESET}"
  echo "${C_IMAGE}--- Images ---${C_RESET}"
  echo "${tgreen}7) List all images${C_RESET}"
  echo "${tred}8) Remove an image${C_RESET}"
  echo "9) Exit"

  read -rp "Select an option: " option
  case $option in
    1)
      docker ps -a --format 'table {{.Names}}\t{{.Ports}}'
      ;;
    2)
      showAutostart
      ;;
    3)
      findPort
      ;;
    4)
      setAutostartNo
      ;;
    5)
      stopContainers
      ;;
    6)
      deleteContainers
      ;;
    7)
      docker images
      ;;
    8)
      removeImages
      ;;
    9)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
