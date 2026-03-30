#!/usr/bin/env bash

WATCH_DIR="$HOME/Downloads"

# --- dependency check ---
for cmd in inotifywait mogrify identify; do
  if ! command -v "$cmd" &>/dev/null; then
    if [[ "$cmd" == "inotifywait" ]]; then
      echo "Error: inotifywait not found. Install with: sudo pacman -S inotify-tools"
    else
      echo "Error: $cmd not found. Install with: sudo pacman -S imagemagick"
    fi
    exit 1
  fi
done

# --- ask resize dimension ---
echo "Watching: $WATCH_DIR (and subdirectories)"
echo
echo "Resize by:"
echo "  1) Width"
echo "  2) Height"
read -rp "Choose [1/2]: " DIM_CHOICE

if [[ "$DIM_CHOICE" == "1" ]]; then
  read -rp "Target width in pixels: " DIM_VALUE
  RESIZE_ARG="${DIM_VALUE}x"
  DIM_LABEL="width → ${DIM_VALUE}px"
elif [[ "$DIM_CHOICE" == "2" ]]; then
  read -rp "Target height in pixels: " DIM_VALUE
  RESIZE_ARG="x${DIM_VALUE}"
  DIM_LABEL="height → ${DIM_VALUE}px"
else
  echo "Invalid choice."
  exit 1
fi

if [[ -z "$DIM_VALUE" || ! "$DIM_VALUE" =~ ^[0-9]+$ ]]; then
  echo "Invalid value: must be a positive integer."
  exit 1
fi

echo
echo "Watching for new jpg/png/webp — resize by $DIM_LABEL"
echo "Press Ctrl+C to quit at any time."
echo

resize_image() {
  local file="$1"
  local w h

  # wait briefly for the file to be fully written
  sleep 0.5

  [[ ! -f "$file" ]] && return

  w=$(identify -format "%w" "$file" 2>/dev/null)
  h=$(identify -format "%h" "$file" 2>/dev/null)

  if [[ -z "$w" || -z "$h" ]]; then
    echo "  Skipped (could not read dimensions): $file"
    return
  fi

  echo "  Found: $(basename "$file")  (${w}x${h})"
  mogrify -resize "$RESIZE_ARG" "$file"

  local w2 h2
  w2=$(identify -format "%w" "$file" 2>/dev/null)
  h2=$(identify -format "%h" "$file" 2>/dev/null)
  echo "  Resized → ${w2}x${h2}: $file"
  echo

  read -rp "Continue watching? [Y/n]: " ANSWER
  if [[ "${ANSWER,,}" == "n" ]]; then
    echo "Exiting."
    kill 0
  fi
}

# watch recursively for close_write and moved_to events (covers downloads finishing)
inotifywait -m -r -e close_write -e moved_to \
  --format "%w%f" \
  "$WATCH_DIR" 2>/dev/null |
while IFS= read -r filepath; do
  case "${filepath,,}" in
    *.jpg|*.jpeg|*.png|*.webp)
      resize_image "$filepath"
      ;;
  esac
done
