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
  echo "${tgreen}1 Install Base Modules(mypy, pypen8, flake8)${treset}"
  echo "${tgreen}2 Precommit${treset}"
  echo "${tgreen}3. Check mypy types${treset}"
  echo "${tblue}4. List requirements.txt${treset}"
  echo "${tblue}5. Install Package by name${treset}"
  echo "${tblue}6. Install all from requirements.txt${treset}"
  echo "${tmagenta}7. Uninstall${treset}"
  echo "${tmagenta}8. Reinstall all${treset}"
  echo "${tmagenta}9. Exit${treset}"
  read -p "Enter the option: " option
  case $option in
    1)
      echo "${tgreen}Installing base packages...${treset}"
      installBasePackages
      menu
      ;;
    2)
      echo "${tgreen}Setting up pre-commit hook for mypy...${treset}"
      preCommitMyPy
      menu
      ;;
    3)
      echo "${tgreen}Checking mypy types...${treset}"
      checkMyPyTypes
      menu
      ;;
    4)
      echo "${tblue}Listing requirements.txt...${treset}"
      listRequirements
      menu
      ;;
    5)
      echo "${tblue}Installing package by name...${treset}"
      installPackageByName
      menu
      ;;
    6)
      echo "${tblue}Installing all packages from requirements.txt...${treset}"
      installAllFromRequirements
      menu
      ;;
    7)
      echo "${tmagenta}Uninstalling package...${treset}"
      uninstallPackage
      menu
      ;;
    8)
      echo "${tmagenta}Reinstalling all packages...${treset}"
      reinstallAll
      menu
      ;;
    9)
      echo "${tmagenta}Exiting...${treset}"
      exit 0
      ;;
    *)
      echo "Invalid option"
      exit 0
      ;;
  esac
}
menu
