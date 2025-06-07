#! /bin/bash 

function prettyEcho(){
  echo "=========================="
  echo "$*"
  echo "=========================="
}

function init(){
  current_dir=$(pwd)
  python3 -m venv venv
  source venv/bin/activate
  python3 -m pip install --upgrade pip
}
function activate(){
  source venv/bin/activate
  python3 -m ensurepip --upgrade
  python3 -m pip install --upgrade pip
}
function initIfNotExists(){
  # if not dir venv and not file requirements.txt
  if [ -d "venv" ] && [ -f "requirements.txt" ]; then
    prettyEcho "Activating virtual environment"
    activate
  else
    prettyEcho "Creating virtual environment and installing base packages"
    init
  fi
}
function installBasePackages(){
  initIfNotExists
  packages=("autopep8" "flake8" "mypy")
  for package in "${packages[@]}"; do
    if grep -q "$package" requirements.txt; then
      prettyEcho "${tblue}$package is already installed${treset}"
      continue
    fi
    installPackageByName $package
  done
}
function checkMyPyTypes(){
  initIfNotExists
  mypy --explicit-package-bases  --ignore-missing-imports .
  deactivate
}
function listRequirements(){
  initIfNotExists
  if [ ! -f "requirements.txt" ]; then
    prettyEcho "No requirements.txt found"
  fi
  bat requirements.txt
  deactivate
}
function installPackageByName(){
  if [ -n "$1" ]; then
    package_name=$1
  else
    read -p "Enter the package name: " package_name
  fi
  initIfNotExists
  python3 -m pip install $package_name
  pip freeze > requirements.txt
  deactivate
}
function installAllFromRequirements(){
  initIfNotExists
  python3 -m pip install -r requirements.txt
  deactivate
}
function uninstallPackage(){
  initIfNotExists
  package_name=$(cat requirements.txt | fzf)
  package_name=$(echo $package_name | cut -d'=' -f1)
  python3 -m pip uninstall $package_name
  pip freeze > requirements.txt
  deactivate
}
function reinstallAll(){
  rm -rf venv
  initIfNotExists
  python3 -m pip install -r requirements.txt
  deactivate
}

function preCommitMyPy(){
  HOOK_FILE=".git/hooks/pre-commit"

  # If .git/hooks does not exist, create it
  mkdir -p .git/hooks

  # Write hook content
  cat <<'EOL' > "$HOOK_FILE"
#!/bin/bash

VENV_DIR="venv"
MYPY="$VENV_DIR/bin/mypy"

# If virtualenv not found or mypy not installed, exit with error
if [[ ! -x "$MYPY" ]]; then
  echo "❌ mypy not found at $MYPY"
  echo "💡 Activate your venv and run: pip install mypy"
  exit 1
fi

# Run mypy check
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

# Make it executable
chmod +x "$HOOK_FILE"

# Show contents
bat "$HOOK_FILE"
}


function menu(){
  menu_items=(
    "Install Base Modules(mypy, pypen8, flake8)"
    "Precommit MyPy to .git/hooks/pre-commit"
    "Check MyPy Types"
    "List Installed Requirements"
    "View requirements.txt"
    "Install Package by Name"
    "Install All from requirements.txt"
    "Uninstall Package"
    "Reinstall All Packages"
    "Exit"
    )

    #foreach item in menu_items and show index and item
  echo "=========================="
  echo "Select an option:"
  #without colors
  for i in "${!menu_items[@]}"; do
    echo "$((i + 1)). ${menu_items[i]}"
  done
  echo "=========================="
  read -p "Enter your choice: " option
  if [[ -z "$option" ]]; then
    echo "${tmagenta}No option selected, exiting.${treset}"
    exit 0
  fi
  if [[ "$option" -eq 1 ]]; then
    initIfNotExists
    menu
  fi
  if [[ "$option" -eq 2 ]]; then
    preCommitMyPy
    menu
  fi
  if [[ "$option" -eq 3 ]]; then
    checkMyPyTypes
    menu
  fi
  if [[ "$option" -eq 4 ]]; then
    installPackageByName
    menu
  fi
  if [[ "$option" -eq 5 ]]; then
    installAllFromRequirements
    menu
  fi
  if [[ "$option" -eq 6 ]]; then
    uninstallPackage
    menu
  fi
  if [[ "$option" -eq 7 ]]; then
    reinstallAll
    menu
  fi
  if [[ "$option" -eq 8 ]]; then
    listRequirements
    menu
  fi
  if [[ "$option" -eq 9 ]]; then
    echo "Exiting..."
    exit 0
  fi
}
menu
