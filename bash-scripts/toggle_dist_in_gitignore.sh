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

# Check current state
if grep -qE "^[#]*${TARGET}$" "$GITIGNORE"; then
  if grep -qE "^#${TARGET}$" "$GITIGNORE"; then
    # Uncomment dist
    sed -i "s/^#${TARGET}$/${TARGET}/" "$GITIGNORE"
    echo "Uncommented 'dist' in .gitignore"
    echo "Removing dist from git cache..."
    git rm -rf --cached dist >/dev/null 2>&1 || true
  else
    # Comment dist
    sed -i "s/^${TARGET}$/#${TARGET}/" "$GITIGNORE"
    echo "Commented 'dist' in .gitignore"
  fi
else
  # If dist line doesn’t exist, append it commented
  echo "Not found dist in .gitignore"
fi
