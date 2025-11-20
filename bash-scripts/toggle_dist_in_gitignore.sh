#!/usr/bin/env bash
# toggle_dist_in_gitignore

set -e

GITIGNORE=".gitignore"
TARGET="dist"

# Ensure .gitignore exists
if [ ! -f "$GITIGNORE" ]; then
  echo ".gitignore not found"
  exit 1
fi

# Regex: optional spaces, optional '#', optional spaces, dist, optional slash, end of line
REGEX="^[[:space:]]*#?[[:space:]]*${TARGET}/?$"

if grep -qE "$REGEX" "$GITIGNORE"; then
  if grep -qE "^[[:space:]]*#[[:space:]]*${TARGET}/?$" "$GITIGNORE"; then
    # Uncomment
    sed -i "s/^[[:space:]]*#[[:space:]]*${TARGET}\/\?$/${TARGET}\//" "$GITIGNORE"
    echo "Uncommented 'dist' in .gitignore"
    git rm -rf --cached dist >/dev/null 2>&1 || true
  else
    # Comment
    sed -i "s/^[[:space:]]*${TARGET}\/\?$/# ${TARGET}\//" "$GITIGNORE"
    echo "Commented 'dist' in .gitignore"
  fi
else
  echo "Not found dist in .gitignore"
fi
