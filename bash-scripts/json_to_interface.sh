#!/bin/bash

function pretty_echo() {
  echo "================================"
  echo "$*"
  echo "================================"
}

# Check if quicktype is installed
if ! command -v quicktype &> /dev/null; then
  pretty_echo "${tmagenta}quicktype not found. Installing it globally...${treset}"
  npm install -g quicktype
else
  pretty_echo "${tgreen}quicktype found. Proceeding with conversion.${treset}"
fi

# Get clipboard content
clipboard=$(xclip -o -selection clipboard)

if [ -z "$clipboard" ]; then
  pretty_echo "${tred}Clipboard is empty. Please copy a JSON object.${treset}"
  exit 1
else
  pretty_echo "${tgreen}Clipboard content detected.${treset}"
fi

# Validate JSON
if ! echo "$clipboard" | jq empty 2>/dev/null; then
  pretty_echo "${tred}Clipboard content is not valid JSON.${treset}"
  exit 1
else
  pretty_echo "${tgreen}Valid JSON. Proceeding...${treset}"
fi

# Ask for interface name
read -p "Enter interface name like MyInterface, will be IMyInterface: " interface_name
if [ -z "$interface_name" ]; then
  pretty_echo "${tred}Interface name cannot be empty.${treset}"
  exit 1
fi

interface_name="${interface_name}"

# Work directory
cd ~/Downloads || exit 1

# Generate .ts file using quicktype (generates interfaces by default)
echo "$clipboard" | quicktype --lang ts --just-types --top-level "$interface_name" -s json -o clipboard.ts

# Check if file was created
if [ -f clipboard.ts ]; then
  mv clipboard.ts "${interface_name}.ts"
  pretty_echo "${tgreen}File renamed to ${interface_name}.ts${treset}"
else
  pretty_echo "${tred}Failed to create clipboard.ts file.${treset}"
  exit 1
fi

# Cleanup: remove comments and empty lines
sed -i '/\/\*\*/,/\*\//d' "${interface_name}.ts"         # Multi-line block comments
sed -i '/\/\*.*\*\//d' "${interface_name}.ts"            # Single-line block comments
sed -i 's/\/\/.*//' "${interface_name}.ts"               # Single-line `//` comments
sed -i '/^\s*$/d' "${interface_name}.ts"                 # Empty lines

# Show result
pretty_echo "${tgreen}Final cleaned TypeScript output:${treset}"
bat "${interface_name}.ts"

# Copy to clipboard
if command -v xclip &> /dev/null; then
  xclip -sel clip < "${interface_name}.ts"
  notify-send "TypeScript interface ${interface_name} copied to clipboard"
else
  notify-send "TypeScript interface ${interface_name} generated but xclip not found, not copied to clipboard"
fi
