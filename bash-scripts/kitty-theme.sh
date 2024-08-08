#!/bin/bash
# https://github.com/dexpota/kitty-themes
thheme_file=$(ls ~/.config/kitty/kitty-themes/themes | fzf)

rm ~/.config/kitty/theme.conf

ln -s ~/.config/kitty/kitty-themes/themes/$thheme_file ~/.config/kitty/theme.conf

kill -9 $PPID
