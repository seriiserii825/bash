#!/usr/bin/env bash
# Generates an ed25519 SSH key for GitHub/Bitbucket, adds it to ssh-agent and ~/.ssh/config, copies .pub to clipboard

SSH_DIR="$HOME/.ssh"
CONFIG="$SSH_DIR/config"
DEFAULT_EMAIL="seriiburduja@gmail.com"

echo "Host:"
select HOST_NAME in github bitbucket; do
  case $HOST_NAME in
    github)    HOST="github.com";    break ;;
    bitbucket) HOST="bitbucket.org"; break ;;
    *) echo "Invalid choice" ;;
  esac
done

read -rp "Email [$DEFAULT_EMAIL]: " EMAIL
EMAIL=${EMAIL:-$DEFAULT_EMAIL}

DEFAULT_KEY="id_ed25519_$HOST_NAME"
read -rp "Key file name [$DEFAULT_KEY]: " KEY_NAME
KEY_NAME=${KEY_NAME:-$DEFAULT_KEY}
KEY="$SSH_DIR/$KEY_NAME"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 1. generate key
if [ -f "$KEY" ]; then
  read -rp "$KEY already exists. Overwrite? [y/N]: " OVERWRITE
  if [[ "$OVERWRITE" =~ ^[yY]$ ]]; then
    rm -f "$KEY" "$KEY.pub"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" || exit 1
  else
    echo "Using existing key"
  fi
else
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" || exit 1
fi

# 2. add key to ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
fi
ssh-add "$KEY"
ssh-add -l

# 3. configure ~/.ssh/config
touch "$CONFIG"
if grep -qE "^Host[[:space:]]+$HOST\$" "$CONFIG"; then
  echo "Host $HOST already exists in $CONFIG — check IdentityFile manually:"
  grep -A5 -E "^Host[[:space:]]+$HOST\$" "$CONFIG"
else
  cat >> "$CONFIG" <<EOF

# $HOST_NAME
Host $HOST
  HostName $HOST
  User git
  IdentityFile ~/.ssh/$KEY_NAME
  IdentitiesOnly yes
EOF
  echo "Added Host $HOST to $CONFIG"
fi
chmod 600 "$CONFIG"

# 4. copy public key to clipboard
echo ""
cat "$KEY.pub"
if command -v xclip &>/dev/null; then
  tr -d '\n' < "$KEY.pub" | xclip -selection clipboard
  echo "Public key copied to clipboard"
elif command -v xsel &>/dev/null; then
  tr -d '\n' < "$KEY.pub" | xsel -b -i
  echo "Public key copied to clipboard"
elif command -v wl-copy &>/dev/null; then
  tr -d '\n' < "$KEY.pub" | wl-copy
  echo "Public key copied to clipboard"
fi

echo ""
if [ "$HOST_NAME" = "github" ]; then
  echo "Add it on GitHub: Settings → SSH and GPG keys → New SSH key"
  echo "https://github.com/settings/ssh/new"
else
  echo "Add it on Bitbucket: Personal settings → SSH keys → Add key"
  echo "https://bitbucket.org/account/settings/ssh-keys/"
fi

# 5. test connection
echo ""
read -rp "Press Enter after adding the key to test connection (or q to skip): " TEST
if [ "$TEST" != "q" ]; then
  ssh -T "git@$HOST"
fi
