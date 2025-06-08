#!/bin/bash
set -e

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

echo "✅ Done: pyproject.toml is now uv-compatible with Python 3.10 requirements."
