#!/bin/bash

## list tmux sessions
tmux list-sessions

sessions=()
while IFS= read -r line; do
    sessions+=("$line")
done < <(tmux list-sessions)

## check if there are any sessions
if [ ${#sessions[@]} -eq 0 ]; then
    echo "No tmux sessions found."
    exit 1
fi

read -p "Select or create or delete, c/s/d: " choice

if [[ $choice == "c" ]]; then
    read -p "Enter session name: " session_name
    tmux new-session -s "$session_name" -d
    tmux attach-session -t "$session_name"
elif [[ $choice == "s" ]]; then
    echo "Select a session to attach to:"
    # select with fzf
    session_name=$(printf '%s\n' "${sessions[@]}" | fzf --height 40% --reverse --inline-info)
    if [ -z "$session_name" ]; then
        echo "No session selected."
        exit 1
    fi
    session_name=$(echo "$session_name" | awk -F: '{print $1}')
    tmux attach-session -t "$session_name"
  elif [[ $choice == "d" ]]; then
    echo "Select a session to delete:"
    # select with fzf
    session_name=$(printf '%s\n' "${sessions[@]}" | fzf --height 40% --reverse --inline-info)
    if [ -z "$session_name" ]; then
        echo "No session selected."
        exit 1
    fi
    session_name=$(echo "$session_name" | awk -F: '{print $1}')
    tmux kill-session -t "$session_name"
else
    echo "Invalid choice. Please enter 'c' or 's'."
fi

tmux ls
