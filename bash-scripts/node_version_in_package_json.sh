#!/bin/bash

# Find package.json (prefer current dir, then search up)
find_package_json() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/package.json" ]]; then
            echo "$dir/package.json"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

PKG=$(find_package_json)

if [[ -z "$PKG" ]]; then
    echo "No package.json found in current directory or any parent directory."
    exit 1
fi

echo "Found: $PKG"

# Check if engines.node already exists
EXISTING=$(node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('$PKG', 'utf8'));
console.log(pkg.engines && pkg.engines.node ? pkg.engines.node : '');
" 2>/dev/null)

if [[ -n "$EXISTING" ]]; then
    echo "engines.node is already set to: \"$EXISTING\""
    read -rp "Do you want to change it? [y/N] " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# Ask for version
echo "Enter Node.js version (e.g. 20.12.0, 22.*, >=18.0.0):"
read -rp "> " VERSION

if [[ -z "$VERSION" ]]; then
    echo "No version entered. Aborted."
    exit 1
fi

# If input is just digits (e.g. "22"), expand to "22.*"
if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    VERSION="${VERSION}.*"
    echo "Expanded to: $VERSION"
fi

# Write to package.json using node
node -e "
const fs = require('fs');
const path = '$PKG';
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
pkg.engines = pkg.engines || {};
pkg.engines.node = '$VERSION';
fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + '\n');
console.log('Set engines.node = \"$VERSION\" in ' + path);
"
