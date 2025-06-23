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

# Ask for type name
read -p "Enter type name like MyType, will be TMyType: " type_name
if [ -z "$type_name" ]; then
  pretty_echo "${tred}Type name cannot be empty.${treset}"
  exit 1
fi
type_name="T${type_name}"

# Work directory
cd ~/Downloads || exit 1

# Generate .ts file using quicktype
echo "$clipboard" | quicktype --lang ts --just-types --top-level "$type_name" -s json -o clipboard.ts

# Check if file was created
if [ -f clipboard.ts ]; then
  mv clipboard.ts "${type_name}.ts"
  pretty_echo "${tgreen}File renamed to ${type_name}.ts${treset}"
else
  pretty_echo "${tred}Failed to create clipboard.ts file.${treset}"
  exit 1
fi

# Cleanup: remove comments and empty lines
sed -i '/\/\*\*/,/\*\//d' "${type_name}.ts"         # Multi-line block comments
sed -i '/\/\*.*\*\//d' "${type_name}.ts"            # Single-line block comments
sed -i 's/\/\/.*//' "${type_name}.ts"               # Single-line `//` comments
sed -i '/^\s*$/d' "${type_name}.ts"                 # Empty lines

# Convert interface to type
sed -i 's/interface/type/g' "${type_name}.ts"
sed -i "s/{/ = {/g" "${type_name}.ts"

# Show result
pretty_echo "${tgreen}Final cleaned TypeScript output:${treset}"
bat "${type_name}.ts"

# Copy to clipboard
if command -v xclip &> /dev/null; then
  xclip -sel clip < "${type_name}.ts"
  notify-send "TypeScript type ${type_name} copied to clipboard"
else
  notify-send "TypeScript type ${type_name} generated but xclip not found, not copied to clipboard"
fi
