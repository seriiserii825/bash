#!/bin/bash

echo "PHP files with whitespace/empty lines before <?php:"
echo "===================================================="

# Temporary file to store problematic files
temp_file=$(mktemp)

find . -type f -name "*.php" | while read -r file; do
    first_byte=$(head -c 1 "$file" | od -An -tx1 | tr -d ' ')
    
    if [ "$first_byte" != "3c" ] && [ -n "$first_byte" ]; then
        if head -c 100 "$file" | grep -q "<?php"; then
            echo ""
            echo "Found: $file"
            echo "First character (hex): $first_byte"
            echo "First 3 lines:"
            head -n 3 "$file" | cat -A
            echo "---"
            echo "$file" >> "$temp_file"
        fi
    fi
done

echo "===================================================="
echo "Scan complete."
echo ""

# Count problematic files
file_count=$(wc -l < "$temp_file" 2>/dev/null || echo "0")

if [ "$file_count" -eq 0 ]; then
    echo "No files with whitespace before <?php found."
    rm -f "$temp_file"
    exit 0
fi

echo "Found $file_count file(s) with whitespace before <?php."
echo ""
read -p "Do you want to remove the whitespace from these files? (y/n): " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    echo ""
    echo "Removing whitespace..."
    
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Create backup
            cp "$file" "$file.bak"
            
            # Remove leading whitespace and empty lines before <?php
            perl -i -pe 's/\A\s+(?=<\?php)//s' "$file"
            
            echo "✓ Fixed: $file (backup: $file.bak)"
        fi
    done < "$temp_file"
    
    echo ""
    echo "Done! Backups created with .bak extension."
    echo "If everything looks good, you can remove backups with: find . -name '*.php.bak' -delete"
else
    echo "No changes made."
fi

rm -f "$temp_file"
