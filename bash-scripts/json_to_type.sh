#!/bin/bash

function pretty_echo(){
  echo "================================"
  echo "$*"
  echo "================================"
}

# check if json2ts command exists

if ! command -v json2ts &> /dev/null; then
  pretty_echo "${tmagenta}json2ts command not found. Please install it first.${treset}"
  npm i json-schema-to-typescript -g
else
  pretty_echo "${tgreen}json2ts command found. Proceeding with conversion.${treset}"
fi

clipboard=$(xclip -o -selection clipboard)
if [ -z "$clipboard" ]; then
  pretty_echo "${tred}Clipboard is empty. Please copy a JSON object to the clipboard.${treset}"
  exit 1
else
  pretty_echo "${tgreen}Clipboard content detected. Proceeding with conversion.${treset}"
fi

# check if clipboard content is valid JSON
if ! echo "$clipboard" | jq empty 2>/dev/null; then
  pretty_echo "${tred}Clipboard content is not valid JSON. Please copy a valid JSON object.${treset}"
  exit 1
else
  pretty_echo "${tgreen}Clipboard content is valid JSON. Proceeding with conversion.${treset}"
fi


read -p "Enter type name like MyType, will be TMyType: " type_name
if [ -z "$type_name" ]; then
  pretty_echo "${tred}Type name cannot be empty. Please provide a valid type name.${treset}"
  exit 1
fi
type_name="T${type_name}"

old_name="NoName"

cd ~/Downloads
json2ts -i <(echo "$clipboard") -o clipboard.ts
bat clipboard.ts

if [ -f clipboard.ts ]; then
  mv clipboard.ts "${type_name}.ts"
  pretty_echo "${tgreen}File renamed to ${type_name}.ts${treset}"
else
  pretty_echo "${tred}Failed to create clipboard.ts file.${treset}"
  exit 1
fi

# inside the file replace old_name with type_name
sed -i "s/${old_name}/${type_name}/g" "${type_name}.ts"
pretty_echo "${tgreen}TypeScript file ${type_name}.ts created successfully.${treset}"
bat "${type_name}.ts"

# replace interface with type
sed -i 's/interface/type/g' "${type_name}.ts"

# add = after type name
sed -i "s/type ${type_name}/type ${type_name} =/g" "${type_name}.ts"

# Remove multi-line block comments like /** ... */
sed -i '/\/\*\*/,/\*\//d' "${type_name}.ts"

# Remove single-line block comments like /* eslint-disable */
sed -i '/\/\*.*\*\//d' "${type_name}.ts"

# remove empty lines
sed -i '/^\s*$/d' "${type_name}.ts"  # remove empty lines

bat "${type_name}.ts"

# copy file to clipboard

if command -v xclip &> /dev/null; then
  xclip -sel clip < "${type_name}.ts"
  pretty_echo "${tgreen}TypeScript file ${type_name}.ts copied to clipboard.${treset}"
else
  pretty_echo "${tred}xclip command not found. Please install it to copy the file to clipboard.${treset}"
fi
