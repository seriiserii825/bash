#!/bin/bash -x


function installWP(){
  HOST_UID=$(id -u) HOST_GID=$(id -g) docker-compose run --rm wpcli core install \
    --url="http://localhost:80" \
    --title="My Site" \
    --admin_user=admin \
    --admin_password=admin \
    --admin_email=admin@gmail.com \
    --skip-email
}

function getCurrentTheme(){
  current_dir=$(basename "$(pwd)")
  echo "$current_dir.local"
}

function currentThemeToHosts(){
  current_theme=$(getCurrentTheme)
  theme_name="127.0.0.1 ${current_theme}"
  # check if theme name is already in /etc/hosts
  if grep -q "$theme_name" /etc/hosts; then
    echo "Theme name $theme_name already exists in /etc/hosts"
  else
    # add theme name to /etc/hosts
    echo "$theme_name" | sudo tee -a /etc/hosts > /dev/null
    sudo cat /etc/hosts
  fi
}

function themeToNginx(){
  current_dir_path=$(pwd)
  current_theme=$(getCurrentTheme)
  # go up 3 time
  cd ../../..
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

}

function changeUrl(){
  theme_name=$(getCurrentTheme)
  docker-compose run --rm wpcli option update home "http://${theme_name}"
  docker-compose run --rm wpcli option update siteurl "http://${theme_name}"
}

# installWP
if [ ! -f front-page.php ]; then
  echo "${tmagenta}No front-page.php found, exiting.${treset}"
  exit 1
fi
# currentThemeToHosts
# themeToNginx
changeUrl
