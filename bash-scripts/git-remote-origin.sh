#!/usr/bin/env bash
# Sets or adds GitHub/Bitbucket remote origin from clipboard URL (git@ or https)

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
# убрать префикс "git clone "
URL="${URL#git clone }"
URL=$(echo "$URL" | xargs)

# нормальная проверка
if [[ ! "$URL" =~ ^(git@github\.com:|https://github\.com/|git@bitbucket\.org:|https://bitbucket\.org/) ]]; then
  echo "Not a GitHub/Bitbucket URL: [$URL]"
  exit 1
fi

echo "Detected: $URL"

echo ""
echo "Action:"
echo "  1) set-url  (меняет URL у существующего origin, напр. репо переехал/поменяли протокол)"
echo "  2) add      (добавляет новый remote, напр. upstream, или когда origin ещё не задан)"
read -rp "Choose [1/2]: " CHOICE

case "$CHOICE" in
  1)
    if git remote set-url origin "$URL"; then
      echo "Done: remote origin set to $URL"
    else
      echo "Failed to set remote origin"
      exit 1
    fi
    ;;
  2)
    read -rp "Remote name [origin]: " REMOTE_NAME
    # на случай, если случайно вставили "git clone ..." или сам URL вместо имени
    REMOTE_NAME="${REMOTE_NAME#git clone }"
    REMOTE_NAME=$(echo "$REMOTE_NAME" | xargs)
    if [[ -z "$REMOTE_NAME" || "$REMOTE_NAME" =~ ^(git@|https?://) ]]; then
      REMOTE_NAME="origin"
    fi
    if git remote add "$REMOTE_NAME" "$URL"; then
      echo "Done: added remote $REMOTE_NAME -> $URL"
    else
      echo "Failed to add remote $REMOTE_NAME"
      exit 1
    fi
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac
