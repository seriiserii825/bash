#!/bin/bash

# Get session name from current directory
SESSION_NAME=$(basename "$PWD")

# Check if we're already in a tmux session and if it matches the session name
if tmux list-sessions 2>/dev/null | grep -q "^$SESSION_NAME:" && [ "$(tmux display-message -p '#S')" != "$SESSION_NAME" ]; then
  echo "Session '$SESSION_NAME' already exists. Attaching..."
  tmux attach-session -t "$SESSION_NAME"
  exit 0
fi

# Create new session (detached)
tmux new-session -d -s "$SESSION_NAME" -c "$PWD" -n nvim

tmux new-window -t "$SESSION_NAME" -n "node" -c "$PWD"
tmux new-window -t "$SESSION_NAME" -n "zsh" -c "$PWD"

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
