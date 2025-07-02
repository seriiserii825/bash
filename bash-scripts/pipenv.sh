#!/bin/bash

function prettyEcho() {
  echo "=========================="
  echo "$*"
  echo "=========================="
}

function initIfNotExists() {
  if [ ! -f "Pipfile" ]; then
    prettyEcho "Creating Pipfile..."
    pipenv --python 3
  else
    prettyEcho "Pipfile already exists."
  fi
  if [ ! -d ".venv" ]; then
    prettyEcho "Creating virtual environment..."
    mkdir .venv
  else
    prettyEcho "Activating existing virtual environment..."
  fi
}

function installBasePackages() {
  initIfNotExists
  packages=("autopep8" "flake8" "mypy")
  for package in "${packages[@]}"; do
    if pipenv graph | grep -q "$package"; then
      prettyEcho "$package is already installed"
    else
      pipenv install --dev "$package"
    fi
  done
}

function checkMyPyTypes() {
  initIfNotExists
  pipenv run mypy --explicit-package-bases --ignore-missing-imports .
}

function listRequirements() {
  initIfNotExists
  prettyEcho "Current Pipfile.lock packages:"
  bat Pipfile
}

function installPackageByName() {
  read -p "Enter the package name: " package_name
  initIfNotExists
  pipenv install "$package_name"
}

function installAll() {
  initIfNotExists
  if [ -f "Pipfile" ]; then
    pipenv install
  else
    prettyEcho "No Pipfile.lock found. Run 'pipenv lock' first."
  fi
}

function installAllFromRequirements(){
  initIfNotExists
  pipenv install -r requirements.txt
  rm -rf venv requirements.txt
}

function uninstallPackage() {
  initIfNotExists
  package_name=$(pipenv lock -r | grep -v '#' | cut -d '=' -f1 | fzf)
  if [ -n "$package_name" ]; then
    pipenv uninstall "$package_name"
  fi
}

function reinstallAll() {
  prettyEcho "Removing existing virtual environment..."
  rm -rf .venv Pipfile.lock
  pipenv install
}

function preCommitMyPy() {
  HOOK_FILE=".git/hooks/pre-commit"

  mkdir -p .git/hooks

  cat <<'EOL' > "$HOOK_FILE"
#!/bin/bash

echo "🔍 Running mypy..."
pipenv run mypy --explicit-package-bases --ignore-missing-imports .

STATUS=$?

if [ $STATUS -ne 0 ]; then
  echo "❌ Commit aborted due to mypy errors."
  exit 1
fi

echo "✅ mypy passed. Proceeding with commit."
exit 0
EOL

  chmod +x "$HOOK_FILE"
  bat "$HOOK_FILE"
}

function menu() {
  echo "1. Install Base Modules (mypy, autopep8, flake8)"
  echo "2. Pre-commit mypy hook"
  echo "3. Check mypy types"
  echo "4. List Pipfile requirements"
  echo "5. Install package by name"
  echo "6. Install all from Pipfile"
  echo "6.1 Install all from requirements.txt and remove them"
  echo "7. Uninstall package"
  echo "8. Reinstall all packages"
  echo "9. Exit"

  read -p "Enter the option: " option
  case $option in
    1) installBasePackages; menu ;;
    2) preCommitMyPy; menu ;;
    3) checkMyPyTypes; menu ;;
    4) listRequirements; menu ;;
    5) installPackageByName; menu ;;
    6) installAll; menu ;;
    6.1) installAllFromRequirements; menu ;;
    7) uninstallPackage; menu ;;
    8) reinstallAll; menu ;;
    9) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid option"; exit 0 ;;
  esac
}

menu
