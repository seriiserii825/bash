#!/bin/bash
set -e

NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

echo "=== Remove Nginx Site ==="
echo ""

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed!"
    exit 1
fi

# List all configs (exclude default)
CONFIGS=$(ls -1 "$NGINX_SITES_AVAILABLE" | grep -v "^default$" || true)

if [ -z "$CONFIGS" ]; then
    echo "No sites found."
    exit 0
fi

# Select config with fzf
SELECTED=$(echo "$CONFIGS" | fzf --height=15 --prompt="Select site to remove: ")

if [ -z "$SELECTED" ]; then
    echo "No site selected. Exiting."
    exit 0
fi

echo "→ Selected: $SELECTED"
read -p "Remove this site? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove symlink and config
sudo rm -f "${NGINX_SITES_ENABLED}/${SELECTED}"
sudo rm -f "${NGINX_SITES_AVAILABLE}/${SELECTED}"

echo "✓ Removed: $SELECTED"

# Test and restart nginx
if sudo nginx -t; then
    sudo systemctl restart nginx
    echo "✓ Nginx restarted"
else
    echo "Warning: Nginx config test failed"
fi
