#!/bin/bash

maim -f jpg -s ~/Downloads/screen.jpg 
tesseract ~/Downloads/screen.jpg ~/Downloads/screen
sed '/^[[:space:]]*$/d' ~/Downloads/screen.txt | xclip -selection clipboard

