#!/usr/bin/env bash
# Moves fzf-selected files to an existing or new directory, copies new paths to clipboard

echo "Select files to move (TAB to select multiple, ENTER to confirm):"
mapfile -t selected_files < <(find . -mindepth 1 \( -name '.git' -o -name 'node_modules' \) -prune -o \( -type f -o -type d \) -print | sed 's|^\./||' | sort | fzf --multi --prompt="Files > ")

if [[ ${#selected_files[@]} -eq 0 ]]; then
    echo "No files selected. Exiting."
    exit 1
fi

echo ""
echo "Selected ${#selected_files[@]} file(s):"
printf '  %s\n' "${selected_files[@]}"
echo ""

echo "What do you want to do?"
action=$(printf "Choose existing directory\nCreate new directory" | fzf --prompt="Action > ")

if [[ -z "$action" ]]; then
    echo "No action selected. Exiting."
    exit 1
fi

if [[ "$action" == "Choose existing directory" ]]; then
    echo ""
    echo "Choose destination directory (ENTER to confirm):"
    dest_dir=$(find . \( -name '.git' -o -name 'node_modules' \) -prune -o -type d -print | sed 's|^\./||' | grep -v '^$' | sort | fzf --prompt="Directory > ")

    if [[ -z "$dest_dir" ]]; then
        echo "No directory selected. Exiting."
        exit 1
    fi
else
    echo ""
    echo "Choose parent directory for the new folder (ENTER to confirm):"
    parent_dir=$(find . -type d | sed 's|^\./||' | grep -v '^$' | sort | fzf --prompt="Parent > ")

    if [[ -z "$parent_dir" ]]; then
        echo "No parent directory selected. Exiting."
        exit 1
    fi

    echo ""
    read -rp "New directory name: " new_dir_name

    if [[ -z "$new_dir_name" ]]; then
        echo "No name provided. Exiting."
        exit 1
    fi

    dest_dir="$parent_dir/$new_dir_name"
    mkdir -p "$dest_dir"
    echo "Created: $dest_dir"
fi

echo ""
echo "Moving files to: $dest_dir"
new_paths=()
for file in "${selected_files[@]}"; do
    mv -- "$file" "$dest_dir/"
    new_path="$dest_dir/$(basename "$file")"
    new_paths+=("$new_path")
    echo "  Moved: $file -> $new_path"
done

for path in "${new_paths[@]}"; do
    echo -n "$path" | xclip -selection clipboard
    sleep 0.05
done
echo ""
echo "Copied ${#new_paths[@]} path(s) to clipboard history (one per entry)."
echo "Done."
