#!/bin/bash

set -e

# Export UID/GID for container use
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# ─────────────────────────────────────────────────────────────
# Setup colors for output
tblue=$(tput setaf 4)
tgreen=$(tput setaf 2)
tmagenta=$(tput setaf 5)
treset=$(tput sgr0)

function prettyEcho(){
  echo "------------------"
  echo -e "$*"
  echo "------------------"
}

# ─────────────────────────────────────────────────────────────
# Ask for project folder
echo "Need to enter folder name, that will be created after cloning the repository."
echo "From folder name will be created project url like: http://folder_name.local"
read -p "Enter folder name: " folder_name
if [ -z "$folder_name" ]; then
  echo "Folder name cannot be empty."
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
echo "Waiting for MySQL to be ready..."
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

# Create wp-config.php
docker-compose run \
  -e HOME=/tmp \
  --rm wpcli config create \
  --dbname=wordpress \
  --dbuser=wp_user \
  --dbpass=wp_pass \
  --dbhost=mysql

# Install WordPress (this creates the DB tables)
docker-compose run \
  -e HOME=/tmp \
  -e WP_CLI_DISABLE_CACHE=1 \
  -e WP_CLI_PHP_ARGS="-d memory_limit=512M" \
  --rm wpcli core install \
    --url="http://${theme_name}" \
    --title="My Site" \
    --admin_user=admin \
    --admin_password=admin \
    --admin_email=admin@gmail.com \
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
notify-send "WordPress Ready" "http://${theme_name}"
