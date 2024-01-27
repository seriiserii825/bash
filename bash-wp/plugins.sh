#! /bin/bash 

# check if don't exists file front-page.php
if [ ! -f "front-page.php" ]; then
  echo "${tmagenta}File front-page.php not found!${treset}"
  exit 1
fi 


local_plugins=( 
  "advanced-custom-fields-pro-6_0_6.zip"
)

server_plugins=(
  "classic-editor"
  "tinymce-advanced"
  "stops-core-theme-and-plugin-updates"
  "safe-svg"
)

function getInstalledPlugins(){
  all_plugins=()
  cd ../../plugins
  plugins=( $(ls -d */) )
  if [[ ${#plugins[@]} -eq 0 ]]; then
    echo "${tmagenta}No plugins installed!${treset}"
    exit 1
  fi
  for plugin in "${plugins[@]}"
  do 
    plugin_name=${plugin%?}
    all_plugins+=($plugin_name)
  done
  echo "${all_plugins[@]}"
}


function installPlugins(){
  local local_plugins=$1
  local server_plugins=$2
  for plugin in "${local_plugins[@]}"
  do
    wp plugin install ~/Documents/plugins-wp/$plugin --activate
  done

  for plugin in "${server_plugins[@]}"
  do
    wp plugin install $plugin --activate
  done
}

function installOne(){
  local local_plugins=($1 "Exit")
  local server_plugins=($2 "Exit")
  PS3='Please select local plugin: '
  COLUMNS=1
  select plugin in "${local_plugins[@]}"
  do
    if [[ $plugin == "Exit" ]]; then
      break
    fi
    wp plugin install ~/Documents/plugins-wp/$plugin --activate
  done

  PS3='Please select server plugin: '
  COLUMNS=1
  select plugin in "${server_plugins[@]}"
  do
    if [[ $plugin == "Exit" ]]; then
      break
    fi
    wp plugin install $plugin --activate
  done
}

function uninstallAll(){
  local plugins=$(getInstalledPlugins)
  for plugin in "${plugins[@]}"
  do 
    wp plugin deactivate $plugin
    wp plugin uninstall $plugin
  done
}

function uninstallOne(){
  local plugins=$(getInstalledPlugins)
  echo "${plugins[@]}"
  PS3='Please select local plugin: '
  COLUMNS=1
  select plugin in "${plugins[@]}"
  do
    if [[ $plugin == "Exit" ]]; then
      break
    fi
    wp plugin deactivate $plugin
    wp plugin uninstall $plugin
  done
}

select action in "List" "InstallOne" "InstallAll" "UninstallOne" "UninstallAll" "Exit"
do
  case $action in
    "List" ) wp plugin list ;;
    "InstallOne" ) installOne "${local_plugins[*]}" "${server_plugins[*]}" ;;
    "InstallAll" ) installPlugins "${local_plugins[*]}" "${server_plugins[*]}" ;;
    "UninstallOne") uninstallOne ;;
    "UninstallAll") uninstallAll ;;
    "Exit" ) exit;;
  esac
done
