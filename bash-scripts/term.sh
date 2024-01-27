#!/bin/bash

# # exec i3-sensible-terminal; layout splith; resize set width 80%
# i3-msg 'workspace 1:Terminal; append_layout /home/serii/i3wm-office/scripts/workspace1.json'
# (termite &)
# (termite &)


# Set the terminal emulator you want to use
terminal_emulator="i3-sensible-terminal"

# Start a new terminal in a vertical split with 25% width
exec $terminal_emulator && resize set width 80 0
