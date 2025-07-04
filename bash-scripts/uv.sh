#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  🌀  UV Project Manager  –  now with Ruff lint + format guard
# ─────────────────────────────────────────────────────────────

# ── Config ───────────────────────────────────────────────────
VENV_DIR=".venv"
PYPROJECT_FILE="pyproject.toml"

# ── Helpers ──────────────────────────────────────────────────
prettyEcho() {
  echo -e "${tblue}==========================${treset}"
  echo -e "$*"
  echo -e "${tblue}==========================${treset}"
}

# Ensure Ruff is installed system‑wide (Arch Linux)
ensureRuff() {
  if ! command -v ruff >/dev/null 2>&1; then
    prettyEcho "🐍 Installing Ruff system‑wide with pacman…"
    sudo pacman -Sy --needed --noconfirm ruff
  else
    prettyEcho "✅ Ruff already installed"
  fi
}

# ── Core setup ───────────────────────────────────────────────
init() {
  # 1. virtual env
  if [[ ! -d "$VENV_DIR" ]]; then
    prettyEcho "🔧 Creating uv virtual environment…"
    uv venv "$VENV_DIR"
  else
    prettyEcho "✅ Virtual environment already exists"
  fi

  uv add ruff

  # 2. pyproject.toml skeleton
  if [[ ! -f "$PYPROJECT_FILE" ]]; then
    prettyEcho "📄 Creating pyproject.toml…"
    cat <<EOF > "$PYPROJECT_FILE"
[project]
name = "my_project"
version = "0.1.0"
description = ""

[tool.ruff]
line-length = 88
exclude = [
    "migrations",
    "tests",
    "docs",
    "build",
    "dist",
    "venv",
    ".venv",
    ".git",
    "__pycache__",
]
fix = true
target-version = "py312"  # <- specify Python 3.12 explicitly here

[tool.ruff.lint]
select = [
    "F401",  # Unused import
    "F403",  # Wildcard import
    "F405",  # Name may be undefined, or defined from star imports
    "F841",  # Local variable is assigned to but never used
    "E501",  # Line too long
    "I",     # Import sorting (isort-compatible)
]
```
EOF
  else
    prettyEcho "✅ pyproject.toml already exists"
    # add ruff setting in pyproject.toml if not present
    if ! grep -q '\[tool.ruff\]' "$PYPROJECT_FILE"; then
      prettyEcho "🔧 Adding Ruff settings to pyproject.toml…"
      cat <<EOF >> "$PYPROJECT_FILE"
[tool.ruff]
line-length = 88
exclude = [
    "migrations",
    "tests",
    "docs",
    "build",
    "dist",
    "venv",
    ".venv",
    ".git",
    "__pycache__",
]
fix = true
target-version = "py312"  # <- specify Python 3.12 explicitly here

[tool.ruff.lint]
select = [
    "F401",  # Unused import
    "F403",  # Wildcard import
    "F405",  # Name may be undefined, or defined from star imports
    "F841",  # Local variable is assigned to but never used
    "E501",  # Line too long
    "I",     # Import sorting (isort-compatible)
]
EOF
    fi


    # Remove empty dependency array that blocks uv auto‑tracking
    if grep -q 'dependencies\s*=\s*\[\s*\]' "$PYPROJECT_FILE"; then
      prettyEcho "🧹 Removing empty dependencies=[] from pyproject.toml"
      sed -i '/dependencies\s*=\s*\[\s*\]/d' "$PYPROJECT_FILE"
    fi
  fi
}

# ── UV wrappers ──────────────────────────────────────────────
sync()          { init; prettyEcho "🔄 Syncing project with uv…"; uv sync; }
installPackage(){ init; package_name="${1:-$(read -p '📦 Package to install: ' x && echo $x)}"; uv add "$package_name"; }
uninstallPackage(){
  init
  packages=$(uv pip list | tail -n +3 | awk '{print $1}' | fzf --multi)
  [[ -z "$packages" ]] && { echo "No package selected"; return; }
  for pkg in $packages; do uv remove "$pkg"; done
}
listPackages()  { init; uv pip list; }
reinstall()     { init; rm -rf "$VENV_DIR"; prettyEcho "🔄 Reinstalling all packages…"; uv sync; }

# ── Ruff integration ────────────────────────────────────────
checkRuff() {
  ensureRuff
  prettyEcho "🔍 Running Ruff (check + format)…"
  ruff check . --fix || { echo "❌ Ruff check failed"; exit 1; }
  ruff format .        || { echo "❌ Ruff format failed"; exit 1; }
  prettyEcho "✅ Ruff clean!"
}

preCommitRuff() {
  ensureRuff
  HOOK_FILE=".git/hooks/pre-commit"
  mkdir -p .git/hooks

  cat <<'EOL' > "$HOOK_FILE"
#!/usr/bin/env bash
echo "🔍 Running Ruff pre‑commit hook…"

if ! command -v ruff >/dev/null 2>&1; then
  echo "❌ Ruff not found. Install it with: sudo pacman -S ruff"
  exit 1
fi

ruff check . --fix || { echo "❌ Commit aborted (Ruff check)"; exit 1; }
ruff format .      || { echo "❌ Commit aborted (Ruff format)"; exit 1; }

echo "✅ Ruff passed. Proceeding with commit."
exit 0
EOL

  chmod +x "$HOOK_FILE"
  bat "$HOOK_FILE" 2>/dev/null || cat "$HOOK_FILE"
  prettyEcho "✅ Git pre‑commit hook installed."
}

# ── Misc helpers ─────────────────────────────────────────────
migrateRequirementsTxt() {
  init
  [[ ! -f "requirements.txt" ]] \
    && { prettyEcho "❌ requirements.txt not found"; return; }

  prettyEcho "📦 Converting requirements.txt → pyproject.toml…"
  uv add -r requirements.txt
  rm -f requirements.txt venv
  prettyEcho "✅ Migration complete."
}

# ── Menu UI ──────────────────────────────────────────────────
menu() {
  echo ""
  echo "🌀 ${tgreen}UV Project Manager (Ruff edition)${treset}"
  echo " 1. Ruff check"
  echo " 2. Install Package"
  echo " 3. Sync"
  echo " 4. Uninstall Package"
  echo " 5. Reinstall all packages"
  echo " 6. List installed packages"
  echo " 7. Migrate requirements.txt → pyproject.toml"
  echo " 8. Init Project + install pre‑commit hook"
  echo " 9. Exit"
  read -p "Choose option: " opt

  case $opt in
    1) checkRuff;           menu ;;
    2) installPackage;      menu ;;
    3) sync;                menu ;;
    4) uninstallPackage; reinstall;   menu ;;
    5) reinstall;           menu ;;
    6) listPackages;        menu ;;
    7) migrateRequirementsTxt; menu ;;
    8) init; preCommitRuff; menu ;;
    9) echo "Goodbye 👋"; exit 0 ;;
    *) echo "❌ Invalid option"; exit 1 ;;
  esac
}

# ── Kick things off ──────────────────────────────────────────
menu
