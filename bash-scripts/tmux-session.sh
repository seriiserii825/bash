#!/bin/bash

# Get session name from current directory
SESSION_NAME=$(basename "$PWD")

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "Session '$SESSION_NAME' already exists. Attaching..."
  tmux attach-session -t "$SESSION_NAME"
  exit 0
fi

# Create new session
tmux new-session -d -s "$SESSION_NAME" -c "$PWD" 

# Second window: node REPL
tmux new-window -t "$SESSION_NAME:" -n shell -c "$PWD" "node"

# Third window: zsh
tmux new-window -t "$SESSION_NAME:" -n shell -c "$PWD" "zsh"

# Optional: switch to first window
tmux select-window -t "$SESSION_NAME:1"

# Attach to session
tmux attach-session -t "$SESSION_NAME"

