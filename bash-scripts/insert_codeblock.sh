#!/bin/bash

# Put code snippet into clipboard
echo -e '```\n\n```' | xclip -selection clipboard

# Simulate Ctrl+V paste
xdotool key ctrl+v

