#!/usr/bin/env bash

read -rp "Word to search: " word
[[ -z "$word" ]] && echo "No word provided." && exit 1

read -rp "File type (e.g. php, js, vue): " ext
[[ -z "$ext" ]] && echo "No file type provided." && exit 1

mapfile -t files < <(grep -rl --include="*.$ext" "$word" . 2>/dev/null)

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No files found containing '$word' in *.$ext files."
    exit 0
fi

echo ""
echo "Files containing '$word':"
for f in "${files[@]}"; do
    count=$(grep -c "$word" "$f")
    echo "  $f  ($count occurrence$([ "$count" -ne 1 ] && echo s))"
done

echo ""
read -rp "Open all in neovim? [y/N] " answer
if [[ "${answer,,}" == "y" ]]; then
    nvim "${files[@]}"
fi
