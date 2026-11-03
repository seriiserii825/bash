#!/usr/bin/env bash
# Finds site folders by name (case-insensitive, partial match) in ~/Sites and ~/Local Sites
# Usage: find-site.sh [name]   e.g. find-site.sh borg

name="$1"
if [[ -z "$name" ]]; then
    read -rp "Folder name to find: " name
fi
[[ -z "$name" ]] && echo "No name provided." && exit 1

dirs=("$HOME/Sites" "$HOME/Local Sites")

found=0
for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r match; do
        echo "$match"
        found=1
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -iname "*$name*" 2>/dev/null | sort)
done

if [[ $found -eq 0 ]]; then
    echo "No folders matching '$name' in ${dirs[*]}."
    exit 1
fi
