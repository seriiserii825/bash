#!/bin/bash

function removeImages(){
  # Get image list once and store it
  image_list=$(docker images --format "{{.ID}} {{.Repository}} {{.Tag}}")
  echo "$image_list" | nl

  # Prompt user
  read -rp "Enter the index of the image to remove (comma separated for multiple): " indexes

  # Convert input into array
  IFS=',' read -ra index_array <<< "$indexes"

  # Remove selected images
  for index in "${index_array[@]}"; do
    image_id=$(echo "$image_list" | sed -n "${index}p" | awk '{print $1}')
    if [ -n "$image_id" ]; then
      docker rmi "$image_id"
    else
      echo "Invalid index: $index"
    fi
  done
}

menu=(
  "1) List all images",
  "2) Remove an image",
)

for i in "${menu[@]}"; do
  echo "$i"
done

read -rp "Select an option: " option
case $option in
  1)
    docker images
    ;;
  2)
    removeImages
    ;;
  *)
    echo "Invalid option. Please try again."
    ;;
esac
