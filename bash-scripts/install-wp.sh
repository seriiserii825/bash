#!/bin/bash 

current_dir=$(pwd)
dir_name=$(basename "$current_dir")
theme_name="${dir_name}.local"

function currentThemeToHosts(){
  theme_name=$1
  theme_host="127.0.0.1 ${theme_name}"
  # check if theme name is already in /etc/hosts
  if grep -q "$theme_host" /etc/hosts; then
    echo "${tmagenta}Theme name $theme_host already exists in /etc/hosts${treset}"
  else
    # add theme name to /etc/hosts
    echo "$theme_host" | sudo tee -a /etc/hosts > /dev/null
    cat /etc/hosts
  fi
}

function themeToNginx(){
  current_theme=$1
  # check for docker dir
  if [ ! -d "docker" ]; then
    echo "${tmagenta}No docker directory found, exiting.${treset}"
    exit 1
  fi
  cd docker
  # check for nginx dir
  if [ ! -d "nginx" ]; then
    echo "${tmagenta}No nginx directory found, exiting.${treset}"
    exit 1
  fi
  cd nginx
  # check for nginx.docker file
  if [ ! -f "default.conf" ]; then
    echo "${tmagenta}No default.conf file found, exiting.${treset}"
    exit 1
  fi
  # check if file line with server_naem
  if grep -q "server_name" default.conf; then
    # replace with new one
    sed -i "s/server_name .*/server_name ${current_theme};/" default.conf
  else
    # add after listen 80;
    sed -i "/listen 80;/a \ \ \ \ server_name ${current_theme};" default.conf
  fi
  echo "${tgreen}Nginx configuration updated for ${current_theme}${treset}"
}

function changeUrl(){
  theme_name=$1
  docker-compose run --rm wpcli option update home "http://${theme_name}"
  docker-compose run --rm wpcli option update siteurl "http://${theme_name}"
  echo "${tgreen}WordPress site URL updated to http://${theme_name}${treset}"
}

function installWP(){
  theme_name=$1
  HOST_UID=$(id -u) HOST_GID=$(id -g) docker-compose run --rm wpcli core install \
    --url="http://$theme_name" \
    --title="My Site" \
    --admin_user=admin \
    --admin_password=admin \
    --admin_email=admin@gmail.com \
    --skip-email

  echo "${tgreen}WordPress installed successfully at http://${theme_name}${treset}"
}
currentThemeToHosts "$theme_name"
themeToNginx "$theme_name"
changeUrl "$theme_name"
installWP "$theme_name"
notify-send "WordPress Installation" "Your WordPress site is ready at http://${theme_name}"
