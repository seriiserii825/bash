#! /bin/bash
cd ~/Documents/bash-apps

apps=( "nvim" "telegram" "phpstorm" "p10k" "zsh" "fzf" "i3wm" "yt-dlp" "ssh" "python3.7" "nvm" "python3.10" "skypeforlinux" "lazygit")


function installAppsDialog() {
  local apps=("$@")
  cmd=(dialog --separate-output --checklist "Select options:" 22 76 16)
  options=()
  for app in "${apps[@]}"
  do
    options+=($app "$app" off)
  done
  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
  clear

  for choice in $choices
  do
    echo "$choice"
    ./i-$choice.sh
  done
  exit 0
}


function uninstallAppsDialog() {
  local apps=("$@")
  cmd=(dialog --separate-output --checklist "Select options:" 22 76 16)
  options=()
  for app in "${apps[@]}"
  do
    options+=($app "$app" off)
  done
  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
  clear

  for choice in $choices
  do
    echo "choice: $choice"
    ./u-$choice.sh
  done
  exit 0
}

function installApps(){
  local apps=("$@")
  apps_to_install=()

  for app in "${apps[@]}"
  do
    #check if app === P10k
    if [ $app == "p10k" ]
    then
      if [ ! -d ~/powerlevel10k ]
      then
        apps_to_install+=($app)
      fi
    elif [ $app == "yt-dlp" ]
    then
      if [ ! -f /usr/local/bin/yt-dlp ]
      then
        apps_to_install+=($app)
      fi
    elif [ $app == "ssh" ]
    then
      if [ ! -d ~/.ssh ]
      then
        apps_to_install+=($app)
      fi
    elif [ $app == "i3wm" ]
    then
      if ! [ -x "$(command -v i3)" ]
      then
        apps_to_install+=($app)
      fi
    elif [ $app == "nvm" ]
    then
      if [ command -v nvm >/dev/null 2>&1 ]
      then
        apps_to_install+=($app)
      fi
    else
      # check if app is installed
      if ! [ -x "$(command -v $app)" ]
      then
        apps_to_install+=($app)
      fi
    fi
    # show apps to install
  done
  if [ ${#apps_to_install[@]} -eq 0 ]
  then
    echo "All apps are installed"
  else
    echo "Apps to install: ${apps_to_install[@]}"
    installAppsDialog "${apps_to_install[@]}"
  fi
}


function uninstallApps(){
  local apps=("$@")
  apps_to_uninstall=()

  for app in "${apps[@]}"
  do
    #check if app === p10k
    if [ $app == "p10k" ]
    then
      if [ -d ~/powerlevel10k ]
      then
        apps_to_uninstall+=($app)
      fi
      #check if app === yt-dlp
    elif [ $app == "yt-dlp" ]
    then
      if [ -f /usr/local/bin/yt-dlp ]
      then
        apps_to_uninstall+=($app)
      fi
    elif [ $app == "ssh" ]
    then
      if [ -d ~/.ssh ]
      then
        apps_to_uninstall+=($app)
      fi
    elif [ $app == "i3wm" ]
    then
      if [ -x "$(command -v i3)" ]
      then
        apps_to_install+=($app)
      fi
    elif [ $app == "nvm" ]
    then
      if [ ! command -v nvm >/dev/null 2>&1 ]
      then
        apps_to_install+=($app)
      fi
    else
      # check if app is uninstalled
      if [ -x "$(command -v $app)" ]
      then
        apps_to_uninstall+=($app)
      fi
    fi
    # show apps to uninstall
  done
  if [ ${#apps_to_uninstall[@]} -eq 0 ]
  then
    echo "All apps are uninstalled"
  else
    echo "Apps to uninstall: ${apps_to_uninstall[@]}"
    uninstallAppsDialog "${apps_to_uninstall[@]}"
  fi
}

if [ ! -x "$(command -v dialog)" ]
then
  sudo apt install dialog -y
fi

select opt in Install Uninstall 
do
  case $opt in
    Install)
      installApps "${apps[@]}"
      ;;
  Uninstall)
      uninstallApps "${apps[@]}"
      ;;
  do)
      break
      ;;
  *)
      echo "Invalid option $REPLY"
      ;;
  esac
done

