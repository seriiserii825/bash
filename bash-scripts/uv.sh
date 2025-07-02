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
  uv pip list
}

function checkMyPy() {
  init
  if ! [ -x "$VENV_DIR/bin/mypy" ]; then
    echo "mypy not installed. Installing..."
    uv add mypy
  fi
  # Run mypy inside .venv
  "$VENV_DIR/bin/mypy" --explicit-package-bases --ignore-missing-imports .
}


function installBasePackages(){
  init
  packages=("autopep8" "flake8" "mypy")
  for package in "${packages[@]}"; do
    if grep -q "$package" pyproject.toml; then
      prettyEcho "${tblue}$package is already installed${treset}"
      continue
    fi
    installPackage $package
  done
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

function reinstall() {
  init
  rm -rf "$VENV_DIR"
  prettyEcho "🔄 Reinstalling all packages..."
  uv sync
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
  rm -rf venv requirements.txt
}

function menu() {
  echo ""
  echo "🌀 UV Project Manager (no , no requirements.txt)"
  echo "${tblue}1. Init Project (create venv + pyproject.toml)${treset}"
  echo "${tblue}1.1 Install base packages${treset}"
  echo "${tblue}2 Sync${treset}"
  echo "${tblue}3 Reinstall${treset}"
  echo "${tgreen}4. Install Package${treset}"
  echo "${tmagenta}5. Uninstall Package${treset}"
  echo "${tgreen}6. List Installed Packages${treset}"
  echo "${tblue}7. Check Types with mypy${treset}"
  echo "${tgreen}8. Setup Pre-Commit Hook for mypy${treset}"
  echo "${tblue}9. Migrate requirements.txt to pyproject.toml${treset}"
  echo "${tmagenta}10. Exit${treset}"
  read -p "Choose option: " opt

  case $opt in
    1) init; menu ;;
    1.1) installBasePackages; menu ;;
    2) sync; menu ;;
    3) reinstall; menu ;;
    4) installPackage; menu ;;
    5) uninstallPackage; menu ;;
    6) listPackages; menu ;;
    7) checkMyPy; menu ;;
    8) preCommitMyPy; menu ;;
    9) migrateRequirementsTxt; menu ;;
    10) echo "Goodbye 👋"; exit 0 ;;
    *) echo "❌ Invalid option"; exit 1 ;;
  esac
}

menu
