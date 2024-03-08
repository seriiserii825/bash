#! /bin/bash  
source /home/serii/Documents/bash/bash-scripts/bash-libs/printArray.sh
source /home/serii/Documents/bash/bash-scripts/bash-libs/multipleSelect.sh
# check if don't exists file front-page.php
if [ ! -f "front-page.php" ]; then
  echo "${tmagenta}File front-page.php not found!${treset}"
  exit 1
fi 

currrent_path=$(pwd)
# echo "Current path: $currrent_path"
plugin_dir="$(dirname "$(dirname "$currrent_path")")/plugins/*"

local_plugins=( 
  "advanced-custom-fields-pro-6_0_6.zip",
  "all-in-one-wp-migration-7-79.zip",
  "seo-by-rank-math.zip",
  "wpglobus.zip",
  "wpglobus-plus.zip",
  "advanced-bulk-edit-v1.3.zip",
  "all-in-one-wp-migration-7-79.zip"
)

server_plugins=(
  "classic-editor",
  "tinymce-advanced",
  "stops-core-theme-and-plugin-updates",
  "safe-svg",
  "contact-form-7",
  "contact-form-7-honeypot",
  "wp-mail-smtp",
  "cookie-notice",
  "wps-hide-login",
  "seo-by-rank-math",
  "wp-pagenavi",
  "error-log-monitor",
  "query-monitor",
  "post-duplicator",
  "woocommerce",
  "easy-woocommerce-auto-sku-generator",
  "wc-fields-factory",
  "webp-express",
  "3d-flipbook-dflip-lite",
  "flow-flow-social-streams",
  "add-to-any",
  "woo-ajax-mini-cart",
  "wp-smushit",
)

function getInstalledPlugins(){
  local files=($(find $plugin_dir -maxdepth 0 -type d -exec basename {} \;))
  echo "${files[@]}"
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

function uninstallPlugins(){
  local plugins=($(getInstalledPlugins))
  selected_plugins=($(multipleSelect "${plugins[@]}"))
  for plugin in "${selected_plugins[@]}"
  do 
    wp plugin deactivate $plugin
    wp plugin uninstall $plugin
  done
}

select action in "List" "Instal" "Uninstall" "Exit"
do
  case $action in
    "List" ) wp plugin list ;;
    "Install" ) installPlugins "${local_plugins[*]}" "${server_plugins[*]}" ;;
    "Uninstall") uninstallPlugins;;
    "Exit" ) exit;;
  esac
done
