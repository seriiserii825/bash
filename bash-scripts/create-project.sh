#! /bin/bash

# copy the folder /home/radu/Desktop/docs/ar-starter in current folder

project_starter_folder="/home/serii/Sites/wp-projects/bs-vite"

# Define the folder path you want to check
folder_to_check="/home/serii/Sites/wp-projects"

# Get the current working directory
current_directory="$(pwd)"

# Check if you are inside the specified folder
if [ "$current_directory" != "$folder_to_check" ]; then
  echo "You are not in the specified folder"
  cd "$folder_to_check"
fi

echo "Enter project name: "
read project_name

if [ -d "$project_name" ]; then
  echo "Folder $project_name already exists"
  exit 1
fi

cp -r "$project_starter_folder" "$project_name"

cd "$project_name"

# remove .git folder
rm -rf .git

# replace all occurences of ar-starter with project_name
find . -type f -exec sed -i "s/bs-vite/$project_name/g" {} \;


# replace all occurences of ar_starter with project_name but - replaced with _
project_with_underscores=$(echo $project_name | tr '[:upper:]' '[:lower:]' | tr '-' '_')
find . -type f -exec sed -i "s/bs_vite/$project_with_underscores/g" {} \;

exit 0



