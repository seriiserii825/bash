#!/bin/bash

# if .git/hooks/pre-commit does not exist, create it
if [ ! -f .git/hooks/pre-commit ]; then
    echo "Creating pre-commit hook..."
    touch .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
fi

# paste multiline text in file

cat <<EOL > .git/hooks/pre-commit
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
$MYPY --explicit-package-bases .

STATUS=$?

if [ $STATUS -ne 0 ]; then
  echo "❌ Commit aborted due to mypy errors."
  exit 1
fi

echo "✅ mypy passed. Proceeding with commit."
exit 0
EOL

# Make the pre-commit hook executable
chmod +x .git/hooks/pre-commit
