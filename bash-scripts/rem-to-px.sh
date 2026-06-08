#!/bin/bash
# Converts rem values in a fzf-selected CSS file to px (multiplies by 10), formats with prettier
css_file="$(find . -name "*.scss" | fzf)"

while read -r line; do
  rem_values=$(echo "$line" | grep -oE "[0-9]+(\.[0-9]+)?rem")
  new_line="$line"

  for rem_value in $rem_values; do
    numeric_value=$(echo "$rem_value" | grep -oE "[0-9]+(\.[0-9]+)?")
    px_value=$(awk "BEGIN { printf \"%g\", $numeric_value * 10 }")
    new_line=$(echo "$new_line" | sed "s/${rem_value}/${px_value}px/g")
  done

  if [[ "$new_line" != "$line" ]]; then
    sed -i "s/$line/$new_line/" "$css_file" > /dev/null 2>&1
  fi
done < "$css_file"

yarn prettier --write "$css_file" > /dev/null 2>&1

echo "Done!"
