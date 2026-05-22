#!/usr/bin/env bash

if command -v xclip &>/dev/null; then
  URL=$(xclip -selection clipboard -o 2>/dev/null)
elif command -v xsel &>/dev/null; then
  URL=$(xsel --clipboard --output 2>/dev/null)
elif command -v wl-paste &>/dev/null; then
  URL=$(wl-paste 2>/dev/null)
else
  echo "No clipboard tool found (install xclip, xsel, or wl-paste)"
  exit 1
fi

URL=$(echo "$URL" | tr -d '\n\r' | xargs)

# нормальная проверка
if [[ ! "$URL" =~ ^(git@github\.com:|https://github\.com/) ]]; then
  echo "Not a GitHub URL: [$URL]"
  exit 1
fi

echo "Detected: $URL"

echo ""
echo "Action:"
echo "  1) set-url"
echo "  2) add"
read -rp "Choose [1/2]: " CHOICE

case "$CHOICE" in
  1)
    git remote set-url origin "$URL"
    echo "Done: remote origin set to $URL"
    ;;
  2)
    read -rp "Remote name [origin]: " REMOTE_NAME
    REMOTE_NAME="${REMOTE_NAME:-origin}"
    git remote add "$REMOTE_NAME" "$URL"
    echo "Done: added remote $REMOTE_NAME -> $URL"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac
