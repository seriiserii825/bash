#! /bin/bash

script_dir="$HOME/Documents/bash/bash-scripts"
source "$script_dir/modules/openFileInGit.sh"

args=("$@")

dictionary_path="/home/serii/.config/coc/extensions/node_modules/coc-fzf-preview/spell/en.utf-8.add"

date_now=$(date +"%Y-%m-%d %H:%M:%S")
function gitUpdateAll(){
  dirs=(
    ~/Documents/todo
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

COLUMNS=1
select action in "nvim" "clipboard" "update" "remove_stagged" "check_tracked" "open_file_in_git" "exit";
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
    check_tracked)
      # Check if the file is in the git index
      # find file with fzf
      # file_path=$(git ls-files | fzf --height 40% --reverse --inline-info --preview "bat --color=always {}" --preview-window=up:30%:wrap)
      file_path=$(fzf)
      if [ -z "$file_path" ]; then
        echo "${tmagenta}No file selected${treset}"
        exit 1
      fi
      # Check if the file is in the git index
      if git ls-files --error-unmatch "$file_path" > /dev/null 2>&1; then
        echo "${tblue}File is tracked by git${treset}"
        # ask if want to delete from git
        read -p "Do you want to delete the file from git? (y/n) " answer
        if [[ "$answer" != "y" ]]; then
          echo "${tmagenta}File not deleted from git${treset}"
          exit 0
        fi
        # add to .gitignore and remove from git
        echo "$file_path" >> .gitignore
        git rm --cached "$file_path"
      else
        echo "${tmagenta}File is not tracked by git${treset}"
      fi
      break
      ;;
    open_file_in_git)
      openFileInGit
      break
      ;;
    *)
      echo "${tmagenta}Invalid option${treset}"
      ;;
  esac
done
