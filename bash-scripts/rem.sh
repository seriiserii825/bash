#!/bin/bash
#!/bin/bash
css_file="$(fzf)"

while read -r line; do
  if [[ $line == *"border:"* || $line == *"border-bottom:"* || $line == *"max-width"* || $line == *"linear-gradient"* || $line == *"&"* || $line == *"width: 1px;"* || $line == *"height: 1px;"* ]]; then
    # echo "$line"
    continue
  else
    # Use regular expressions to find pixel values (e.g., "10px", "20px", etc.)
    px_values=$(echo "$line" | grep -oE "[0-9]+px")
    new_line="$line"

    # Iterate through each found pixel value
    for px_value in $px_values; do
      # Extract the numeric value from the pixel value
      numeric_value=$(echo "$px_value" | grep -oE "[0-9]+")

      # Convert the pixel value to rem and divide by 10
      rem_value=$(awk "BEGIN { printf \"%.2f\", $numeric_value / 10 }")

      # Replace the pixel value with the calculated rem value
      new_line=$(echo "$new_line" | sed "s/$px_value/${rem_value}rem/g")

      # echo "'new_line is:' $new_line"
    done
    # Print the modified line
    # echo "$line"
    # echo "$new_line"
    sed -i "s/$line/$new_line/" $css_file > /dev/null 2>&1
  fi
done < "$css_file"

yarn prettier --write $css_file > /dev/null 2>&1

echo "Done!"
