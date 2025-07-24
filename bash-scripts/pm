#! /bin/bash 

# shellcheck source=/home/serii/dotfiles/zsh_modules/zsh_colors
source ~/dotfiles/zsh_modules/zsh_colors

function pipToUv(){
  set -e


  # if uv is not installed
  # check if uv is installed
  if ! command -v uv &> /dev/null; then
    echo "uv is not installed. Please install uv first."
    echo "Install uv in arch with pacman"
    sudo pacman -S uv --noconfirm
  fi


  if [ ! -f requirements.txt ]; then
    echo "requirements.txt not found!"
    exit 1
  fi

  # Initialize Poetry project with Python 3.10 if pyproject.toml doesn't exist
  if [ ! -f pyproject.toml ]; then
    poetry init --python="^3.10" --no-interaction
  else
    echo "pyproject.toml already exists. Skipping initialization."
  fi

  # Add dependencies from requirements.txt
  poetry add $(cat requirements.txt)

  # Remove poetry.lock file (Poetry’s lock)
  rm -f poetry.lock

  # Remove [build-system] section for uv compatibility
  sed -i '/\[build-system\]/,$d' pyproject.toml

  # Replace invalid Poetry-style version with valid PEP 621 syntax for uv
  sed -i 's/requires-python = "\^3\.10"/requires-python = ">=3.10,<4.0"/' pyproject.toml

  # if in .gitignore not uv.lock, add it
  if ! grep -q "uv.lock" .gitignore; then
    echo "uv.lock" >> .gitignore
    echo "Added uv.lock to .gitignore"
  else
    echo "uv.lock already exists in .gitignore"
  fi

  rm -rf .mypy_cache .venv venv requirements.txt
}

function prettyEcho(){
  echo "=========================="
  echo "$*"
  echo "=========================="
}
function initIfNotExists(){
  if ! command -v uv &> /dev/null; then
    echo "uv is not installed. Please install uv first."
    echo "Install uv in arch with pacman"
    sudo pacman -S uv --noconfirm
  fi

  if [ ! -f pyproject.toml ]; then
    uv init .
  fi
}
function installBasePackages(){
  initIfNotExists
  packages=("autopep8" "flake8" "mypy")
  for package in "${packages[@]}"; do
    if grep -q "$package" pyproject.toml; then
      prettyEcho "${tblue}$package is already installed${treset}"
      continue
    fi
    installPackageByName "$package"
  done
}
function checkMyPyTypes(){
  initIfNotExists
  mypy --explicit-package-bases  --ignore-missing-imports .
}
function listInstalledPackages(){
  initIfNotExists
  uv tree
}
function installPackageByName(){
  initIfNotExists
  if [ -n "$1" ]; then
    package_name=$1
  else
    read -r -p "Enter the package name: " package_name
  fi
  uv add "$package_name"
}

function syncAll(){
  initIfNotExists
  uv sync
}

# shellcheck disable=SC2120
function uninstallPackage(){
  initIfNotExists
  if [ -n "$1" ]; then
    package_name=$1
  else
    read -r -p "Enter the package name to uninstall: " package_name
  fi
  uv remove "$package_name"
}

function reinstallAll(){
  initIfNotExists
  uv sync --reinstall
}

function preCommitMyPy(){
  HOOK_FILE=".git/hooks/pre-commit"

  # If .git/hooks does not exist, create it
  mkdir -p .git/hooks

  # Write hook content
  cat <<'EOL' > "$HOOK_FILE"
#!/bin/bash

# Run mypy check
echo "🔍 Running mypy..."
mypy --explicit-package-bases --ignore-missing-imports .

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
  echo "${tblue}4. List installed${treset}"
  echo "${tblue}5. Install Package by name${treset}"
  echo "${tblue}6. Install all${treset}"
  echo "${tmagenta}7. Uninstall${treset}"
  echo "${tmagenta}8. Reinstall all${treset}"
  echo "${tblue}9. Pip to Uv${treset}"
  echo "${tmagenta}10. Exit${treset}"
  read -r -p "Enter the option: " option
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
      echo "${tblue}Listing installed packages...${treset}"
      listInstalledPackages
      menu
      ;;
    5)
      echo "${tblue}Installing package by name...${treset}"
      installPackageByName
      menu
      ;;
    6)
      echo "${tblue}Installing all packages from requirements.txt...${treset}"
      syncAll
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
      echo "${tblue}Pip to uv...${treset}"
      pipToUv
      menu
      ;;
    10)
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
