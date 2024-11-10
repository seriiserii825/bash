#! /bin/bash

file_name="docker-compose.yaml"
env_example_file=".env.example"
if [ ! -f "$file_name" ]; then
    echo "${tmagenta}File $file_name does not exist.${treset}"
    exit 1
fi

read -p "Enter the name of the docker: " docker_name

sed -i "s/course/$docker_name/g" $file_name
sed -i "s/course/$docker_name/g" $env_example_file

echo "${tgreen}Docker name changed to $docker_name${treset}"
