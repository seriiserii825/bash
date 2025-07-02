#!/bin/bash

VENV_DIR=".venv"
PYPROJECT_FILE="pyproject.toml"

function prettyEcho() {
  echo "=========================="
  echo "$*"
  echo "=========================="
}

function init() {
  if [ ! -d "$VENV_DIR" ]; then
    prettyEcho "🔧 Creating uv virtual environment..."
    uv venv "$VENV_DIR"
  else
    prettyEcho "✅ Virtual environment already exists"
  fi

  if [ ! -f "$PYPROJECT_FILE" ]; then
    prettyEcho "📄 Creating pyproject.toml..."
    cat <<EOF > "$PYPROJECT_FILE"
[project]
name = "my_project"
version = "0.1.0"
description = ""
EOF
  else
    prettyEcho "✅ pyproject.toml already exists"
    
    # Remove 'dependencies = []' if it exists (which blocks uv auto-tracking)
    if grep -q 'dependencies\s*=\s*\[\s*\]' "$PYPROJECT_FILE"; then
      prettyEcho "🧹 Removing empty dependencies=[] from pyproject.toml"
      sed -i '/dependencies\s*=\s*\[\s*\]/d' "$PYPROJECT_FILE"
    fi
  fi
}

function sync() {
  init
  prettyEcho "🔄 Syncing project with uv..."
  uv sync
}

function installPackage() {
  read -p "📦 Enter package name to install: " package_name
  init
  uv add "$package_name"
}

function uninstallPackage() {
  init
  packages=$(uv list | tail -n +3 | awk '{print $1}' | fzf --multi)
  if [ -z "$packages" ]; then
    echo "No package selected"
    return
  fi
  for pkg in $packages; do
    uv  uninstall "$pkg"
  done
}

function listPackages() {
  init
  uv  list
}

function checkMyPy() {
  init
  if ! [ -x "$VENV_DIR/bin/mypy" ]; then
    echo "mypy not installed. Installing..."
    uv  install mypy
  fi
  uv venv exec mypy --explicit-package-bases --ignore-missing-imports .
}

function preCommitMyPy() {
  HOOK_FILE=".git/hooks/pre-commit"
  mkdir -p .git/hooks

  cat <<'EOL' > "$HOOK_FILE"
#!/bin/bash

VENV_DIR=".venv"
MYPY="$VENV_DIR/bin/mypy"

if [[ ! -x "$MYPY" ]]; then
  echo "❌ mypy not found at $MYPY"
  echo "💡 Run: uv  install mypy"
  exit 1
fi

echo "🔍 Running mypy..."
"$MYPY" --explicit-package-bases --ignore-missing-imports .

STATUS=$?
if [ $STATUS -ne 0 ]; then
  echo "❌ Commit aborted due to mypy errors."
  exit 1
fi

echo "✅ mypy passed. Proceeding with commit."
exit 0
EOL

  chmod +x "$HOOK_FILE"
  bat "$HOOK_FILE" 2>/dev/null || cat "$HOOK_FILE"
}

function migrateRequirementsTxt() {
  init
  if [ ! -f "requirements.txt" ]; then
    prettyEcho "❌ requirements.txt not found"
    return
  fi

  prettyEcho "📦 Converting requirements.txt to pyproject.toml..."
  uv add -r requirements.txt
  prettyEcho "✅ Migration complete. requirements.txt will be removed."
  rm -f requirements.txt
}

function menu() {
  echo ""
  echo "🌀 UV Project Manager (no , no requirements.txt)"
  echo "1. Init Project (create venv + pyproject.toml)"
  echo "1.1 Sync"
  echo "2. Install Package"
  echo "3. Uninstall Package"
  echo "4. List Installed Packages"
  echo "5. Check Types with mypy"
  echo "6. Setup Pre-Commit Hook for mypy"
  echo "7. Migrate requirements.txt to pyproject.toml"
  echo "8. Exit"
  read -p "Choose option: " opt

  case $opt in
    1) init; menu ;;
    1.1) sync; menu ;;
    2) installPackage; menu ;;
    3) uninstallPackage; menu ;;
    4) listPackages; menu ;;
    5) checkMyPy; menu ;;
    6) preCommitMyPy; menu ;;
    7) migrateRequirementsTxt; menu ;;
    8) echo "Goodbye 👋"; exit 0 ;;
    *) echo "❌ Invalid option"; exit 1 ;;
  esac
}

menu
