#!/bin/bash
# Pick a course folder then a video file with fzf, and play it in mpv with bookmarks support

DOTFILES_MPV_DIR="$HOME/dotfiles/apps/mpv"
COURSES_CSV="$DOTFILES_MPV_DIR/courses.csv"
BOOKMARKS_FILE="$DOTFILES_MPV_DIR/bookmarks"
BOOKMARKS_SCRIPT="$DOTFILES_MPV_DIR/bookmarks.lua"

if [ ! -f "$COURSES_CSV" ]; then
    echo "Courses list not found: $COURSES_CSV"
    exit 1
fi

folder=$(tail -n +2 "$COURSES_CSV" \
    | fzf -d ',' --with-nth=1 --preview 'echo {2}' --prompt="course > " \
    | cut -d',' -f2)

if [ -z "$folder" ]; then
    echo "No folder selected."
    exit 1
fi

video=$(find "$folder" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.webm" -o -iname "*.mov" \) \
    | sort \
    | fzf --prompt="video > ")

if [ -z "$video" ]; then
    echo "No video selected."
    exit 1
fi

mpv --script="$BOOKMARKS_SCRIPT" --script-opts=bookmarks-file="$BOOKMARKS_FILE" "$video"
