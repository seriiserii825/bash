#!/usr/bin/env bash

read -rp "What do you want to do, resize/optimize? [r/o]: " MODE
MODE="${MODE,,}"

if [[ "$MODE" != "r" && "$MODE" != "o" ]]; then
  echo "Invalid option. Use 'r' or 'o'."
  exit 1
fi

read -rp "Directory to scan (default: current): " DIR
DIR="${DIR:-.}"

for cmd in identify mogrify jpegoptim; do
  command -v "$cmd" >/dev/null || {
    echo "Error: $cmd is not installed"
    exit 1
  }
done

IMAGES=()
JPEG_IMAGES=()

echo
echo "Scanning files..."
echo "----------------"

if [[ "$MODE" == "r" ]]; then
  read -rp "Enter minimum WIDTH in pixels: " MIN_W

  while IFS= read -r img; do
    w=$(identify -format "%w" "$img" 2>/dev/null)
    h=$(identify -format "%h" "$img" 2>/dev/null)

    if [[ -n "$w" && "$w" -ge "$MIN_W" ]]; then
      IMAGES+=("$img")
      printf "%5sx%-5s  %s\n" "$w" "$h" "$img"
    fi
  done < <(
    find "$DIR" -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \)
  )

else
  # OPTIMIZE MODE → ALL JPG/JPEG (no size check)
  while IFS= read -r img; do
    JPEG_IMAGES+=("$img")
    echo "$img"
  done < <(
    find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \)
  )
fi

# -------------------------
# RESIZE
# -------------------------
if [[ "$MODE" == "r" ]]; then
  echo
  echo "Found ${#IMAGES[@]} images"

  [[ ${#IMAGES[@]} -eq 0 ]] && exit 0

  read -rp "Enter NEW width in pixels: " NEW_W
  read -rp "Resize these images? (y/N): " CONFIRM
  [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && exit 0

  for img in "${IMAGES[@]}"; do
    echo "Resizing: $img"
    mogrify -resize "${NEW_W}x" "$img"
  done
fi

# -------------------------
# OPTIMIZE
# -------------------------
if [[ "$MODE" == "o" ]]; then
  echo
  echo "Found ${#JPEG_IMAGES[@]} JPEG images"

  [[ ${#JPEG_IMAGES[@]} -eq 0 ]] && exit 0

  read -rp "Optimize ALL JPEG images with jpegoptim (quality 85)? (y/N): " CONFIRM
  [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && exit 0

  for img in "${JPEG_IMAGES[@]}"; do
    echo "Optimizing: $img"
    jpegoptim --max=85 --strip-all "$img"
  done
fi

echo
echo "✅ Done."
