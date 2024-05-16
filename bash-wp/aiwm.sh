#! /bin/bash 
source /home/$USER/Documents/bash/bash-scripts/bash-libs/multipleSelect.sh
source /home/$USER/Documents/bash/bash-scripts/bash-libs/printArray.sh
# check if don't exists file front-page.php
if [ ! -f "front-page.php" ]; then
  echo "${tmagenta}File front-page.php not found!${treset}"
  exit 1
fi 

currrent_path=$(pwd)
# echo "Current path: $currrent_path"
backup_dir_path="$(dirname "$(dirname "$currrent_path")")/ai1wm-backups"
# echo "Backup dir path: $backup_dir_path"
# backups_path="../../ai1wm-backups"

if ! wp plugin is-installed all-in-one-wp-migration; then
  echo "${tmagenta}Plugin All-in-One WP Migration not found!${treset}"
  wp plugin install ~/Documents/plugins-wp/all-in-one-wp-migration-7-79.zip --activate
  echo "${tgreen}Plugin All-in-One WP Migration installed!${treset}"
fi

if ! wp plugin is-installed all-in-one-wp-migration-unlimited-extension; then
  echo "${tmagenta}Plugin All-in-One WP Migration not found!${treset}"
  wp plugin install ~/Documents/plugins-wp/unlimited/all-in-one-wp-migration-unlimited-extension-2.51.zip --activate
  echo "${tgreen}Plugin All-in-One WP Migration unlimited installed!${treset}"
fi

function listBackup(){
  wp ai1wm list-backups
}

function restoreBackup(){
  listBackup

  backup_files=$(ls -t $backup_dir_path | grep '\.wpress')

  PS3='Please enter your choice: '
  COLUMNS=1
  select backup_file in $backup_files
  do
    wp ai1wm restore $backup_file
    wp rewrite flush
    exit 0
  done
}

function restoreBackupFromDownloads(){
  PS3='Please enter your choice: '
  select backup_file in $(ls -t ~/Downloads | grep '\.wpress')
  do
    echo "Selected file: $backup_file"
    cp ~/Downloads/$backup_file $backup_dir_path
    wp ai1wm restore $backup_file
    wp rewrite flush
    exit 0
  done
}

function makeBackup(){
  wp ai1wm backup
  last_file=$(ls -t $backup_dir_path | head -n1)
  echo "Last file: $last_file"
  cp "$backup_dir_path/$last_file" /home/$USER/Downloads
  echo "${tgreen}Backup created!${treset}"
}

function downloadBackup(){
  read -p "Enter domain url: " domain_url
  if [ -z "$domain_url" ]; then
    echo "Domain url is empty!"
    exit 1
  fi

  # get domain name from domain url
  domain_1=$(echo $domain_url | cut -d'/' -f1)
  domain_url=$(echo $domain_url | cut -d'/' -f3 | cut -d':' -f1)

  read -p "Enter backup file name: " backup_file
  if [ -z "$backup_file" ]; then
    echo "Backup file name is empty!"
    exit 1
  fi
  wget "$domain_url/wp-content/ai1wm-backups/$backup_file" $backup_dir_path
  wp ai1wm restore $backup_file
  wp rewrite flush
}

function deleteBackup(){
  wpress_files=()

  for file in $(ls -t $backup_dir_path | grep '\.wpress'); do
    wpress_files+=($file)
  done
  # printArray "${wpress_files[@]}"

  selected_files=($(multipleSelect "${wpress_files[@]}"))

  # printArray "${selected_files[@]}"

  # Process the selected files
  for selected_file in ${selected_files[@]}; do
    # echo "Selected file: $selected_file"
    rm -f $backup_dir_path/$selected_file
  done
}

COLUMNS=1
select choice in  "${tyellow}List${treset}" "${tgreen}Make Backup${treset}" "${tblue}Download Backup${treset}" "${tblue}Restore from Downloads${treset}" "${tblue}Restore Backup${treset}" "${tmagenta}Delete Backup${treset}" "${tmagenta}Exit${treset}"; do
  case $choice in
    "${tyellow}List${treset}" ) listBackup;;
    "${tgreen}Make Backup${treset}" ) makeBackup;;
    "${tblue}Download Backup${treset}" ) downloadBackup;;
    "${tblue}Restore from Downloads${treset}" ) restoreBackupFromDownloads;; 
    "${tblue}Restore Backup${treset}" ) restoreBackup;;
    "${tmagenta}Delete Backup${treset}" ) deleteBackup;;
    "Exit" ) exit;;
  esac
done
