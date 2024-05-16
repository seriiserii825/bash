#! /bin/bash

args=("$@")

dictionary_path="/home/serii/.config/coc/extensions/node_modules/coc-fzf-preview/spell/en.utf-8.add"

date_now=$(date +"%Y-%m-%d %H:%M:%S")
function gitUpdateAll(){
  dirs=(
    ~/serii/Documents/todo
    ~/Documents/Knowledge-base_
    ~/xubuntu 
    ~/.password-store 
    ~/.config/nvim 
    ~/i3wm-home 
    ~/i3wm-office 
    ~/Documents/bash 
    ~/Documents/python-info 
    ~/Documents/python-scripts 
    ~/Documents/chrome-extenstions/tabs-copy
    ~/Documents/python/wp-python
    ~/Documents/chrome-extenstions/autofill)
  for dir in "${dirs[@]}"; do
    echo "=========================================="
    echo "${tblue}Update for $dir${treset}"
    cd $dir
    git add .
    git commit -m "updated by script at $date_now"
    git pull
    git push
    echo "=========================================="
  done
}

function removeStagged(){
  projects_list=$(mgitstatus -e -d 4)
  touch ~/Downloads/list.txt
  echo "${projects_list[@]}" > ~/Downloads/list.txt
  bat ~/Downloads/list.txt
  while read -r line; do
    file_name=$(echo "$line" | cut -d ':' -f 1)
    cd $file_name
    git restore .
    git clean -fd
    cd - > /dev/null
  done < ~/Downloads/list.txt

  rm ~/Downloads/list.txt
}

select action in "nvim" "clipboard" "update" "remove_stagged"
do
  case $action in
    nvim)
      $(git log --pretty="%C(Yellow)%h  %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an: %C(reset)%s" --date=short -100 --reverse > log.log)
      bat log.log
      break
      ;;
    clipboard)
      log=$(git log --since="3am" --pretty=tformat:"%s" --reverse > log.log);
      sed -i 's/feat://' log.log
      cat log.log | xclip -selection clipboard
      rm log.log
      break
      ;;
    update)
      gitUpdateAll
      break
      ;;
    remove_stagged)
      removeStagged
      break
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done
