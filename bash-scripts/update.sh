#!/bin/bash
source ~/.nvm/nvm.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check for package.json
if [ ! -f package.json ]; then
  echo -e "${RED}❌ package.json not found! Please run this script in the project root directory.${NC}"
  exit 1
fi

# Check for engines.node in package.json
if ! grep -q '"engines"' package.json; then
  echo -e "${RED}❌ Error: 'engines' field not found in package.json!${NC}"
  echo -e "${YELLOW}Please add the following to your package.json:${NC}"
  echo -e '  "engines": {'
  echo -e '    "node": "22.*"'
  echo -e '  }'
  exit 1
fi

# Check if engines.node has a value
NODE_VERSION=$(grep -A 2 '"engines"' package.json | grep '"node"' | sed 's/.*"node"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$NODE_VERSION" ]; then
  echo -e "${RED}❌ Error: 'engines.node' field is missing or has no value in package.json!${NC}"
  echo -e "${YELLOW}Please specify a Node.js version in package.json:${NC}"
  echo -e '  "engines": {'
  echo -e '    "node": "22.*"'
  echo -e '  }'
  exit 1
fi

echo -e "${GREEN}✓ Node version specified in package.json: ${NODE_VERSION}${NC}"

# Check if git working directory is clean
if ! git diff-index --quiet HEAD --; then
  echo -e "${RED}❌ Error: You have uncommitted changes in git!${NC}"
  echo -e "${YELLOW}Please commit or stash your changes before running this script.${NC}"
  git status --short
  exit 1
fi

echo -e "${CYAN}🔧 Switching to Node.js 22...${NC}"
nvm use $NODE_VERSION

# Pull latest changes
echo -e "${BLUE}📥 Pulling latest changes from git...${NC}"
if ! git pull; then
  echo -e "${RED}❌ Error: git pull failed!${NC}"
  exit 1
fi

echo -e "${BLUE}📦 Installing dependencies with bun...${NC}"
bun install

echo -e "${CYAN}🏗️  Building project...${NC}"
bun run build

echo -e "${YELLOW}🧹 Cleaning up node_modules...${NC}"
rm -rf node_modules

echo -e "${GREEN}✅ Update completed successfully!${NC}"
