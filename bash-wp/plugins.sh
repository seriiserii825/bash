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
  "advanced-custom-fields-pro-6_0_6"
  "all-in-one-wp-migration-7-79"
  "seo-by-rank-math"
  "wpglobus"
  "wpglobus-plus"
  "advanced-bulk-edit-v1.3"
)

server_plugins=(
  "classic-editor"
  "tinymce-advanced"
  "stops-core-theme-and-plugin-updates"
  "safe-svg"
  "contact-form-7"
  "contact-form-7-honeypot"
  "wp-mail-smtp"
  "cookie-notice"
  "wps-hide-login"
  "seo-by-rank-math"
  "wp-pagenavi"
  "error-log-monitor"
  "query-monitor"
  "post-duplicator"
  "woocommerce"
  "easy-woocommerce-auto-sku-generator"
  "wc-fields-factory"
  "webp-express"
  "3d-flipbook-dflip-lite"
  "flow-flow-social-streams"
  "add-to-any"
  "woo-ajax-mini-cart"
  "wp-smushit"
)

function getInstalledPlugins(){
  local files=($(find $plugin_dir -maxdepth 0 -type d -exec basename {} \;))
  echo "${files[@]}"
}


function installPlugins(){
  local all_plugins=("${local_plugins[@]}" "${server_plugins[@]}")
  local installed_plugins=($(getInstalledPlugins))
  local plugins_to_install=($(echo ${all_plugins[@]} ${installed_plugins[@]} | tr ' ' '\n' | sort | uniq -u))
  selected_plugins=($(multipleSelect "${plugins_to_install[@]}"))
  for plugin in "${selected_plugins[@]}"
  do 
    if [[ " ${local_plugins[@]} " =~ " ${plugin} " ]]; then
      wp plugin install ~/Documents/plugins-wp/$plugin.zip --activate
    else
      wp plugin install $plugin --activate
    fi
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

select action in "List" "Install" "Uninstall" "Exit"
do
  case $action in
    "List" ) wp plugin list ;;
    "Install" ) installPlugins ;;
    "Uninstall") uninstallPlugins;;
    "Exit" ) exit;;
  esac
done
