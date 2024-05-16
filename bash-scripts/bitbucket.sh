#!/bin/bash

clipboard=$(xclip -o -selection clipboard)
if [[ $clipboard == *bitbucket.org* ]]; then
    echo $clipboard  
    echo $clipboard | sed -e 's/bitbucket.org/bitbucket.org-b/' | xclip -selection clipboard
    new_clipboard=$(xclip -o -selection clipboard)
    echo $new_clipboard
  else
    echo "No bitbucket link in clipboard"
fi
