#!/bin/bash

if ! command -v lsof &>/dev/null; then
  echo "lsof not found, installing..."
  sudo pacman -S --noconfirm lsof
fi

PS3="Select action: "
select action in "Check" "Kill" "Quit"; do
  case $action in
    Check)
      read -p "Enter port: " port
      ss -tlnp "sport = :$port"
      ;;
    Kill)
      read -p "Enter port: " port
      pids=$(sudo fuser "${port}/tcp" 2>/dev/null | tr -d ' ')
      if [ -z "$pids" ]; then
        echo "No process found on port $port"
      else
        read -p "Enter PID to kill (or press Enter to kill all: $pids): " input_pid
        target=${input_pid:-$pids}
        echo "$target" | xargs sudo kill
        echo "Killed PID(s): $target"
      fi
      ;;
    Quit)
      break
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done
