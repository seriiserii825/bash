#!/bin/bash
set -e

# Configuration
DOMAIN_SUFFIX="seriiburduja.org"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

# Get current directory and folder name
CURRENT_DIR=$(pwd)
FOLDER_NAME=$(basename "$CURRENT_DIR")

echo "=== Node.js Nginx Site Setup ==="
echo ""

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in current directory!"
    exit 1
fi

echo "✓ package.json found"

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed!"
    echo "Install it with: sudo apt install fzf"
    exit 1
fi

# Determine port range based on folder name prefix
if [[ "$FOLDER_NAME" == nest* ]]; then
    PORT_START=3300
    PORT_END=3399
    PORT_LABEL="NestJS (33xx)"
elif [[ "$FOLDER_NAME" == nuxt* ]]; then
    PORT_START=3000
    PORT_END=3099
    PORT_LABEL="Nuxt (30xx)"
else
    PORT_START=3100
    PORT_END=3299
    PORT_LABEL="Other (31xx-32xx)"
fi

# Generate subdomain and config filename
SUBDOMAIN="${FOLDER_NAME}.${DOMAIN_SUFFIX}"
CONFIG_FILE="${NGINX_SITES_AVAILABLE}/${SUBDOMAIN}"
SYMLINK_PATH="${NGINX_SITES_ENABLED}/${SUBDOMAIN}"

echo "→ Project type: $PORT_LABEL"
echo "→ Subdomain: $SUBDOMAIN"

# Get all used ports from nginx configs and running processes
USED_PORTS=$(grep -rh "proxy_pass http://127.0.0.1:" "$NGINX_SITES_AVAILABLE" 2>/dev/null | \
    grep -oE "127\.0\.0\.1:[0-9]+" | cut -d':' -f2 | sort -n | uniq)

SYSTEM_PORTS=$(ss -tlnp 2>/dev/null | grep -oE "127\.0\.0\.1:[0-9]+" | cut -d':' -f2 | sort -n | uniq)

ALL_USED_PORTS=$(echo -e "${USED_PORTS}\n${SYSTEM_PORTS}" | sort -n | uniq)

# Generate list of available ports in the range
AVAILABLE_PORTS=""
for port in $(seq $PORT_START $PORT_END); do
    if ! echo "$ALL_USED_PORTS" | grep -qx "$port"; then
        AVAILABLE_PORTS="${AVAILABLE_PORTS}${port}\n"
    fi
done

# Select port with fzf
echo ""
SELECTED_PORT=$(echo -e "$AVAILABLE_PORTS" | head -50 | fzf --height=15 --prompt="Select port: ")

if [ -z "$SELECTED_PORT" ]; then
    echo "No port selected. Exiting."
    exit 1
fi

echo "✓ Selected port: $SELECTED_PORT"

# Check if config already exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Warning: Config already exists at $CONFIG_FILE"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Create nginx config
sudo tee "$CONFIG_FILE" > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SUBDOMAIN};
    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:${SELECTED_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

echo "✓ Config created: $CONFIG_FILE"

# Create symlink
if [ ! -L "$SYMLINK_PATH" ]; then
    sudo ln -s "$CONFIG_FILE" "$SYMLINK_PATH"
    echo "✓ Symlink created"
else
    echo "→ Symlink already exists"
fi

# Test and restart nginx
if sudo nginx -t; then
    echo "✓ Nginx config test passed"
    sudo systemctl restart nginx
    echo "✓ Nginx restarted"
else
    echo "Error: Nginx config test failed!"
    sudo rm -f "$SYMLINK_PATH"
    sudo rm -f "$CONFIG_FILE"
    exit 1
fi

# Summary
echo ""
echo "=== Setup Complete ==="
echo "Subdomain: $SUBDOMAIN"
echo "Port: $SELECTED_PORT"
echo "Config: $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "  1. Add DNS record for $SUBDOMAIN"
echo "  2. Start your app on port $SELECTED_PORT"
echo "  3. (Optional) SSL: sudo certbot --nginx -d $SUBDOMAIN"
