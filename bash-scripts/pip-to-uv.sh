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

#pyproject remove from line [build-system] all to the end of file
sed -i '/\[build-system\]/,$d' pyproject.toml

echo "Done: dependencies installed into pyproject.toml with Python 3.10."
echo "Now you can use uv for your project management."
