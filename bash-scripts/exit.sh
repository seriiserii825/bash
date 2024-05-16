#!/bin/bash

# Get the process IDs (PIDs) of Bash instances
zsh_pids=$(pgrep -f zsh)
echo "Bash PIDs: $zsh_pids"

# Check if any Bash instances are running
if [ -n "$zsh_pids" ]; then
  # Loop through each PID and send the exit command
  for pid in $zsh_pids; do
    echo "Exiting Bash instance with PID $pid"
    kill -9 $pid
  done
else
  echo "No Bash instances found to exit."
fi
