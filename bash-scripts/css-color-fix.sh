#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

file=$(find . -type f \( -name "*.scss" -o -name "*.css" \) 2>/dev/null \
  | fzf --prompt="Select file: " \
        --preview="grep -n 'rgb([0-9]* [0-9]* [0-9]* / [0-9]' {} || echo 'No matches'" \
        --preview-window=up:10)

[[ -z "$file" ]] && echo "No file selected." && exit 0

matches=$(grep -n "rgb([0-9]* [0-9]* [0-9]* \/ [0-9]" "$file")

if [[ -z "$matches" ]]; then
  echo "No modern color notation found in: $file"
  exit 0
fi

echo ""
echo "${CYAN}File:${RESET} $file"
echo "─────────────────────────────────────────"

echo ""
echo "${RED}Before:${RESET}"
while IFS= read -r line; do
  echo "  $line"
done <<< "$matches"

echo ""
echo "${GREEN}After:${RESET}"
sed "s/rgb(\([0-9]\+\) \([0-9]\+\) \([0-9]\+\) \/ \([0-9.]\+%\?\))/rgb(\1,\2,\3,\4)/g" "$file" \
  | grep -n "rgb([0-9]*,[0-9]*,[0-9]*" \
  | while IFS= read -r line; do echo "  $line"; done

echo ""
read -p "Apply changes? (y/n): " confirm
[[ "$confirm" != "y" ]] && echo "Aborted." && exit 0

sed -i "s/rgb(\([0-9]\+\) \([0-9]\+\) \([0-9]\+\) \/ \([0-9.]\+%\?\))/rgb(\1,\2,\3,\4)/g" "$file"
echo "Done."
