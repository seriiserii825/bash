#! /bin/bash

clipboard="$(xclip -o -selection clipboard)"
clipboard_content="$(echo $clipboard | tr -d '\n')"
echo "project_url: $clipboard_content"

if [[ -n $clipboard_content && -d $clipboard_content ]]; then
  read -p "Enter session name: " session_name
  read -p "Enter window_1 name: " window_1
  read -p "Enter window_2 name: " window_2
  read -p "Enter window_3 name: " window_3

  if [ -z "$session_name" ]; then
    echo "No session name provided"
    exit 1
  fi

  if [ -z "$window_1" ]; then
    echo "No window_1 name provided"
    exit 1
  else
    echo "window_1: $window_1"
    echo "session_name: $session_name"
    tmux new-session -s $session_name -d -n $window_1 -c $clipboard_content
    tmux list-sessions
  fi

  if [ -z "$window_2" ]; then
    echo "No window_2 name provided"
    exit 1
  else
    tmux new-window -n $window_2 -t $session_name -c $clipboard_content
    echo "window_2: $window_2"
    tmux list-sessions
  fi

  if [ -z "$window_3" ]; then
    echo "No window_3 name provided"
    exit 1
  else
    tmux new-window -n $window_3 -t $session_name -c $clipboard_content
    echo "window_3: $window_3"
  fi
  tmux list-sessions
  tmux attach-session -t $session_name
else
  echo "Clipboard content is either empty or not a valid file path."
fi

