#!/usr/bin/env bash
set -euo pipefail

# dependencies check (bat is optional)
for cmd in fzf rsvg-convert svgo xclip; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd"; exit 1; }
done

# pick svg with fzf
file_path=$(find . -type f -name "*.svg" | fzf)
[ -n "${file_path:-}" ] || { echo "No file selected"; exit 1; }

read -p "Enter mode w/h/s/optimize/a (width/height/size WxH/optimize/all): " choose

file_name="$(basename "$file_path" .svg)"
dir_name="$(dirname "$file_path")"

# Helpers
make_output_name() {
  # $1 suffix like "w-256", "h-128", "256x128", "optimize"
  echo "${dir_name}/${file_name}-${1}.svg"
}

convert_and_optimize() {
  # args: width height out_file
  local w="${1:-}"
  local h="${2:-}"
  local out="${3}"

  # Build rsvg args
  local args=(-f svg "$file_path" -o "$out")
  [ -n "$w" ] && args=(-w "$w" "${args[@]}")
  [ -n "$h" ] && args=(-h "$h" "${args[@]}")

  rsvg-convert "${args[@]}"
  svgo "$out" >/dev/null
  cat "$out" | xclip -selection clipboard
  command -v bat >/dev/null 2>&1 && bat "$out" || echo "Created: $out"
  echo "${tblue:-}Copied to clipboard!${treset:-}"
  echo "${tgreen:-}your file is ready: $(basename "$out")${treset:-}"
}

if [ "$choose" = "optimize" ]; then
  out="$(make_output_name "optimize")"
  svgo "$file_path" -o "$out"
  command -v bat >/dev/null 2>&1 && bat "$out" || echo "Created: $out"
  exit 0
fi

if [ "$choose" = "w" ]; then
  read -p "Enter width: " width
  out="$(make_output_name "w-${width}")"
  convert_and_optimize "$width" "" "$out"
  exit 0
fi

if [ "$choose" = "h" ]; then
  read -p "Enter height: " height
  out="$(make_output_name "h-${height}")"
  convert_and_optimize "" "$height" "$out"
  exit 0
fi

if [ "$choose" = "s" ]; then
  read -p "Enter size (e.g. 256x128): " size
  if [[ ! "$size" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    echo "Invalid size. Use WIDTHxHEIGHT, e.g. 256x128"
    exit 1
  fi
  width="${BASH_REMATCH[1]}"
  height="${BASH_REMATCH[2]}"
  out="$(make_output_name "${width}x${height}")"
  convert_and_optimize "$width" "$height" "$out"
  exit 0
fi

if [ "$choose" = "a" ]; then
  echo "Choose what to set:"
  echo "1) width"
  echo "2) height"
  echo "3) width & height"
  read -p "Enter 1/2/3: " mode

  case "$mode" in
    1)
      read -p "Enter width: " width
      out="$(make_output_name "w-${width}")"
      convert_and_optimize "$width" "" "$out"
      ;;
    2)
      read -p "Enter height: " height
      out="$(make_output_name "h-${height}")"
      convert_and_optimize "" "$height" "$out"
      ;;
    3)
      read -p "Enter size (e.g. 256x128): " size
      if [[ ! "$size" =~ ^([0-9]+)x([0-9]+)$ ]]; then
        echo "Invalid size. Use WIDTHxHEIGHT, e.g. 256x128"
        exit 1
      fi
      width="${BASH_REMATCH[1]}"
      height="${BASH_REMATCH[2]}"
      out="$(make_output_name "${width}x${height}")"
      convert_and_optimize "$width" "$height" "$out"
      ;;
    *)
      echo "Unknown choice"
      exit 1
      ;;
  esac
  exit 0
fi

echo "Unknown mode: $choose"
exit 1
