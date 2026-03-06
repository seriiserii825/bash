#!/bin/bash

read -p "Enter dimensions (width,height) or just width: " input

IFS=',' read -r WIDTH HEIGHT <<< "$input"

if [[ -z "$WIDTH" ]]; then
  echo "Width is required."
  exit 1
fi

ID=$((RANDOM % 1000 + 1))

if [[ -n "$HEIGHT" ]]; then
  URL="https://picsum.photos/id/${ID}/${WIDTH}/${HEIGHT}"
else
  URL="https://picsum.photos/id/${ID}/${WIDTH}"
fi

echo "$URL" | tr -d '\n' | xsel -b -i
echo "Copied: $URL"
