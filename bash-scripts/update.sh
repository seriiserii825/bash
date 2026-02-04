#!/bin/bash
source ~/.nvm/nvm.sh

# check for package.json
if [ ! -f package.json ]; then
  echo "❌ package.json not found! Please run this script in the project root directory."
  exit 1
fi

# check if git working directory is clean
if ! git diff-index --quiet HEAD --; then
  echo "❌ Error: You have uncommitted changes in git!"
  echo "Please commit or stash your changes before running this script."
  git status --short
  exit 1
fi

echo "🔧 Switching to Node.js 22..."
nvm use 22

# pull latest changes
echo "📥 Pulling latest changes from git..."
if ! git pull; then
  echo "❌ Error: git pull failed!"
  exit 1
fi

echo "📦 Installing dependencies with bun..."
bun install

echo "🏗️  Building project..."
bun run build

echo "🧹 Cleaning up node_modules..."
rm -rf node_modules

echo "✅ Update completed successfully!"
