#!/bin/bash

set -e

# check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "${tmagenta}Docker is not running. Please start Docker and try again.${treset}"
  exit 1
fi

# check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
  echo "${tmagenta}docker-compose is not installed. Please install it and try again.${treset}"
  exit 1
fi

function prettyEcho(){
  echo "------------------"
  echo -e "$*"
  echo "------------------"
}

intro_message=$(cat <<'EOF'
==============================
Run the init-wp-docker.sh script
==============================

===============================
Enter name, email, password
Enter the name of the folder for cloning the repository, from the name of which the domain name will be built, example: test -> test.local
The installation will start, containers, wordpress will be installed, creating a default account:

login: admin  
password: admin  
email: admin@gmail.com
===============================

================================
You can change it at the beginning of the installation
After installation, open the browser and go to: http://test.local
Log in to the default admin panel using the login and password above
================================

===============================
Installing plugins and backups (using the wp-python script for favorites)

wb  
wb init  
wb plugins - base plugins  
wb backups - restore from downloads
================================
EOF
)

prettyEcho "${intro_message}"

# Export UID/GID for container use
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# email, user , password
message="By default will be used name: admin, email: admin@gmail.com, password: admin"
prettyEcho "${message}"
read -p "${tmagenta}Do you want to use different admin user, email and password? (y/n): ${treset}" use_custom_admin

if [ $use_custom_admin == "y" ];then 
  read -p "${tblue}Enter name: ${treset}" admin_user
  read -p "${tblue}Enter email: ${treset}" admin_email
  read -p "${tblue}Enter password: ${treset}" admin_password
  if [ -z "$admin_user" ] || [ -z "$admin_email" ] || [ -z "$admin_password" ]; then
    message="Sowething went wrong, will be used default values."
    prettyEcho "${message}"
  fi
else
  admin_user="admin"
  admin_password="admin"
  admin_email="admin@gmail.com"
fi

message="user: ${admin_user}\n email: ${admin_email}\n password: ${admin_password}"
prettyEcho "${message}"

read -p "${tmagenta}Do you want to continue? (y/n): ${treset}" confirm
if [ "$confirm" != "y" ]; then
  message="Exiting script."
  prettyEcho "${message}"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# Setup colors for output
tblue=$(tput setaf 4)
tgreen=$(tput setaf 2)
tmagenta=$(tput setaf 5)
treset=$(tput sgr0)

# ─────────────────────────────────────────────────────────────
# Ask for project folder
message="Need to enter folder name, that will be created after cloning the repository.\n From folder name will be created project url like: http://folder_name.local"
prettyEcho "${message}"
read -p "${tgreen}Enter folder name: ${treset}" folder_name
if [ -z "$folder_name" ]; then
  message="Folder name cannot be empty."
  prettyEcho "${message}"
  exit 1
fi

# ─────────────────────────────────────────────────────────────

# Clone repo
current_user=$(whoami)
if [ "$current_user" == "serii" ]; then
  prettyEcho "${tblue}You are serii, clone with ssh.${treset}"
  url_path="git@github.com:seriiserii825/docker-wp.git"
else
  prettyEcho "${tmagenta}You are not serii, clone with https.${treset}"
  url_path="https://github.com/seriiserii825/docker-wp.git"
fi

git clone "$url_path" "$folder_name"
cd "$folder_name"

# ─────────────────────────────────────────────────────────────
# Setup domain and nginx

theme_name="${folder_name}.local"
theme_host="127.0.0.1 ${theme_name}"

# Add to /etc/hosts if not present
if ! grep -q "$theme_host" /etc/hosts; then
  echo "$theme_host" | sudo tee -a /etc/hosts > /dev/null
  prettyEcho "${tgreen}Added ${theme_name} to /etc/hosts${treset}"
else
  prettyEcho "${tmagenta}${theme_name} already in /etc/hosts${treset}"
fi

# Update nginx default.conf
conf_path="docker/nginx/default.conf"
initial_conf="docker/nginx/initial.conf"

if [ ! -f "$conf_path" ] && [ -f "$initial_conf" ]; then
  cp "$initial_conf" "$conf_path"
fi

if grep -q "server_name" "$conf_path"; then
  sed -i "s/server_name .*/server_name ${theme_name};/" "$conf_path"
else
  sed -i "/listen 80;/a \ \ \ \ server_name ${theme_name};" "$conf_path"
fi
prettyEcho "${tgreen}Updated nginx config for ${theme_name}${treset}"

# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────
# Start docker
prettyEcho "${tgreen}Starting Docker containers...${treset}"
docker-compose up -d --build

# Wait for MySQL to be up (important for wp-cli)
message="Waiting for MySQL to be ready..."
prettyEcho "${message}"
until docker-compose exec -T mysql mysql -uwp_user -pwp_pass -e "SHOW DATABASES;" &> /dev/null; do
  sleep 4
done

# ─────────────────────────────────────────────────────────────
# Download WordPress core (force download, no cache, more memory)
# docker-compose run \
#   -e WP_CLI_DISABLE_CACHE=1 \
#   -e PHP_MEMORY_LIMIT=512M \
#   --rm wpcli core download --force

# Download WordPress core
docker-compose run \
  -e HOME=/tmp \
  -e WP_CLI_DISABLE_CACHE=1 \
  -e WP_CLI_PHP_ARGS="-d memory_limit=512M" \
  --rm wpcli core download --force

if [ -f wp-config.php ]; then
  rm wp-config.php
fi

# ─────────────────────────────────────────────────────────────

# Create wp-config.php
docker-compose run \
  -e HOME=/tmp \
  --rm wpcli config create \
  --dbname=wordpress \
  --dbuser=wp_user \
  --dbpass=wp_pass \
  --dbhost=mysql

docker-compose run \
  -e HOME=/tmp \
  -e WP_CLI_DISABLE_CACHE=1 \
  -e WP_CLI_PHP_ARGS="-d memory_limit=512M" \
  --rm wpcli core install \
    --url="http://${theme_name}" \
    --title="My Site" \
    --admin_user="${admin_user}" \
    --admin_password="${admin_password}" \
    --admin_email="${admin_email}" \
    --skip-email

# Now it's safe to update the home and siteurl options
docker-compose run --rm wpcli option update home "http://${theme_name}"
docker-compose run --rm wpcli option update siteurl "http://${theme_name}"

prettyEcho "${tgreen}WordPress installed at http://${theme_name}${treset}"

# ─────────────────────────────────────────────────────────────
# Restart docker to apply nginx config
docker-compose down
docker-compose up -d --build

# ─────────────────────────────────────────────────────────────
# Notify completion
prettyEcho "${tgreen}🎉 Your local WordPress site is ready at http://${theme_name}${treset}"
message="Your credentials:\nUser: ${admin_user}\nEmail: ${admin_email}\nPassword: ${admin_password}"
prettyEcho "${message}"
notify-send "WordPress Ready" "http://${theme_name}"
