#!/bin/bash

set -e

# Configuration
DOMAIN_SUFFIX="seriiburduja.org"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
PORT_START=3000
PORT_END=3999

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current directory and folder name
CURRENT_DIR=$(pwd)
FOLDER_NAME=$(basename "$CURRENT_DIR")

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Node.js Nginx Site Setup Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}✗ Error: package.json not found in current directory!${NC}"
    echo -e "${RED}  Please run this script from inside a Node.js project.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ package.json found${NC}"

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    echo -e "${RED}✗ Error: fzf is not installed!${NC}"
    echo -e "${YELLOW}  Install it with: sudo apt install fzf${NC}"
    exit 1
fi

echo -e "${GREEN}✓ fzf is available${NC}"

# Generate subdomain from folder name
SUBDOMAIN="${FOLDER_NAME}.${DOMAIN_SUFFIX}"
echo -e "${BLUE}→ Subdomain will be: ${YELLOW}${SUBDOMAIN}${NC}"

# Get all used ports from nginx configs
echo -e "${BLUE}→ Scanning for used ports...${NC}"

USED_PORTS=$(grep -rh "proxy_pass http://127.0.0.1:" "$NGINX_SITES_AVAILABLE" 2>/dev/null | \
    grep -oE "127\.0\.0\.1:[0-9]+" | \
    cut -d':' -f2 | \
    sort -n | \
    uniq)

# Also check ports in use by running processes
SYSTEM_PORTS=$(ss -tlnp 2>/dev/null | grep -oE "127\.0\.0\.1:[0-9]+" | cut -d':' -f2 | sort -n | uniq)

# Combine both lists
ALL_USED_PORTS=$(echo -e "${USED_PORTS}\n${SYSTEM_PORTS}" | sort -n | uniq | grep -E "^3[0-9]{3}$" || true)

echo -e "${YELLOW}Ports already in use (3xxx range):${NC}"
if [ -n "$ALL_USED_PORTS" ]; then
    echo "$ALL_USED_PORTS" | tr '\n' ' '
    echo ""
else
    echo "None"
fi

# Generate list of available ports
AVAILABLE_PORTS=""
for port in $(seq $PORT_START $PORT_END); do
    if ! echo "$ALL_USED_PORTS" | grep -qx "$port"; then
        AVAILABLE_PORTS="${AVAILABLE_PORTS}${port}\n"
    fi
done

# Show first 50 available ports for selection with fzf
echo ""
echo -e "${BLUE}→ Select a port using fzf (showing first 50 available):${NC}"

SELECTED_PORT=$(echo -e "$AVAILABLE_PORTS" | head -50 | fzf --height=15 --prompt="Select port: " --header="Available ports (3000-3999)")

if [ -z "$SELECTED_PORT" ]; then
    echo -e "${RED}✗ No port selected. Exiting.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Selected port: ${YELLOW}${SELECTED_PORT}${NC}"

# Config file path
CONFIG_FILE="${NGINX_SITES_AVAILABLE}/${FOLDER_NAME}"

# Check if config already exists
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠ Warning: Config file already exists at ${CONFIG_FILE}${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}✗ Aborted.${NC}"
        exit 1
    fi
fi

# Create nginx config
echo -e "${BLUE}→ Creating nginx config...${NC}"

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

echo -e "${GREEN}✓ Config created at ${CONFIG_FILE}${NC}"

# Create symlink if it doesn't exist
SYMLINK_PATH="${NGINX_SITES_ENABLED}/${FOLDER_NAME}"
if [ ! -L "$SYMLINK_PATH" ]; then
    echo -e "${BLUE}→ Creating symlink...${NC}"
    sudo ln -s "$CONFIG_FILE" "$SYMLINK_PATH"
    echo -e "${GREEN}✓ Symlink created${NC}"
else
    echo -e "${YELLOW}→ Symlink already exists${NC}"
fi

# Test nginx config
echo -e "${BLUE}→ Testing nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration test passed${NC}"
else
    echo -e "${RED}✗ Nginx configuration test failed!${NC}"
    echo -e "${YELLOW}  Removing created config...${NC}"
    sudo rm -f "$SYMLINK_PATH"
    sudo rm -f "$CONFIG_FILE"
    exit 1
fi

# Restart nginx
echo -e "${BLUE}→ Restarting nginx...${NC}"
sudo systemctl restart nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx restarted successfully${NC}"
else
    echo -e "${RED}✗ Failed to restart nginx${NC}"
    exit 1
fi

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Setup Complete! ✓                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Subdomain:${NC}  ${YELLOW}${SUBDOMAIN}${NC}"
echo -e "  ${BLUE}Port:${NC}       ${YELLOW}${SELECTED_PORT}${NC}"
echo -e "  ${BLUE}Config:${NC}     ${YELLOW}${CONFIG_FILE}${NC}"
echo ""
echo -e "${YELLOW}Don't forget to:${NC}"
echo -e "  1. Configure your DNS to point ${SUBDOMAIN} to your server"
echo -e "  2. Start your Node.js app on port ${SELECTED_PORT}"
echo -e "  3. (Optional) Set up SSL with: sudo certbot --nginx -d ${SUBDOMAIN}"
echo ""
