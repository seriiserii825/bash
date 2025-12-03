#!/bin/bash

# Array to store problematic file paths
problematic_files=()

# Find PHP files that don't start with <?php but contain it
find . -type f -name "*.php" | while read -r file; do
first_byte=$(head -c 1 "$file" | od -An -tx1 | tr -d ' ')

if [ "$first_byte" != "3c" ] && [ -n "$first_byte" ]; then
  if head -c 100 "$file" | grep -q "<?php"; then
    problematic_files+=("$file")
  fi
fi
done

# Export the array for use after the loop
# (Note: the while loop runs in a subshell, so we need to collect files differently)

# Better approach: collect files first, then display
temp_file=$(mktemp)
find . -type f -name "*.php" | while read -r file; do
first_byte=$(head -c 1 "$file" | od -An -tx1 | tr -d ' ')

if [ "$first_byte" != "3c" ] && [ -n "$first_byte" ]; then
  if head -c 100 "$file" | grep -q "<?php"; then
    echo "$file" >> "$temp_file"
  fi
fi
done

# Count problematic files
file_count=$(wc -l < "$temp_file" 2>/dev/null || echo "0")

echo ""
echo "========================================"
echo "Summary: $file_count problematic file(s) found"
echo "========================================"

# Read files into array and display them
if [ "$file_count" -gt 0 ]; then
  # Store in array
  mapfile -t file_list < "$temp_file"

    # Display each file
    for file in "${file_list[@]}"; do
      echo "  - $file"
    done
fi

echo "========================================"
echo "Fixing files..."
echo "========================================"

    # Process each file to remove whitespace before <?php
    fixed_count=0
    for file in "${file_list[@]}"; do
        if [ -f "$file" ]; then
            # Use awk to:
            # 1. Skip everything until we find <?php
            # 2. Remove leading whitespace from the <?php line
            # 3. Print everything from <?php onwards
            awk '
                /<?php/ { 
                    found = 1
                    sub(/^[[:space:]]+/, "")
                }
                found { print }
            ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            
            echo "  ✓ Fixed: $file (backup: $file.bak)"
            ((fixed_count++))
        fi
    done

    echo ""
    echo "Fixed $fixed_count file(s)"

# Clean up
rm -f "$temp_file"
