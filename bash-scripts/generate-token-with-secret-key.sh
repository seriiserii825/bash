#!/usr/bin/env bash

# ── clipboard read ────────────────────────────────────────────────────────────
if [[ -n "$WAYLAND_DISPLAY" ]]; then
  SECRET=$(wl-paste --no-newline 2>/dev/null)
elif [[ -n "$DISPLAY" ]]; then
  SECRET=$(xclip -selection clipboard -o 2>/dev/null)
else
  echo "Error: no display server detected (WAYLAND_DISPLAY / DISPLAY not set)" >&2
  exit 1
fi

if [[ -z "$SECRET" ]]; then
  echo "Error: clipboard is empty — copy the JWT secret key first" >&2
  exit 1
fi

# ── expiry prompt ─────────────────────────────────────────────────────────────
read -rp "Expiry time in seconds [default: 60]: " EXPIRY
EXPIRY="${EXPIRY:-60}"

if ! [[ "$EXPIRY" =~ ^[0-9]+$ ]] || [[ "$EXPIRY" -eq 0 ]]; then
  echo "Error: expiry must be a positive integer (seconds)" >&2
  exit 1
fi

# ── generate JWT (HS256) via Node ─────────────────────────────────────────────
TOKEN=$(node -e "
const crypto = require('crypto');
const secret = $(node -e "process.stdout.write(JSON.stringify(process.argv[1]))" -- "$SECRET");
const now    = Math.floor(Date.now() / 1000);
const exp    = now + $EXPIRY;

const header  = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
const payload = Buffer.from(JSON.stringify({ name: 'Test', surname: 'User', iat: now, exp })).toString('base64url');
const sig     = crypto.createHmac('sha256', secret).update(header + '.' + payload).digest('base64url');

process.stdout.write(header + '.' + payload + '.' + sig);
")

if [[ -z "$TOKEN" ]]; then
  echo "Error: token generation failed" >&2
  exit 1
fi

# ── output ────────────────────────────────────────────────────────────────────
echo ""
echo "Token (expires in ${EXPIRY}s):"
echo "$TOKEN"
echo ""
echo "URL param:"
echo "?token=$TOKEN"
echo ""

# copy token to clipboard
if [[ -n "$WAYLAND_DISPLAY" ]]; then
  echo -n "$TOKEN" | wl-copy 2>/dev/null && echo "Token copied to clipboard."
elif [[ -n "$DISPLAY" ]]; then
  echo -n "$TOKEN" | xclip -selection clipboard 2>/dev/null && echo "Token copied to clipboard."
fi
