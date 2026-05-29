#!/bin/bash
# Uses Ollama/llama3 to summarize clipboard git commits into a short client update, copies result

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
  echo "❌ Ollama is not installed. Please install it from https://ollama.com/"
  exit 1
fi

# Check if xclip is installed
if ! command -v xclip &> /dev/null; then
  echo "❌ xclip is not installed. Please install it: sudo pacman -S xclip (Arch) or sudo apt install xclip (Ubuntu)"
  exit 1
fi

# Grab commits from clipboard
COMMITS=$(xclip -o -selection clipboard)

if [ -z "$COMMITS" ]; then
  echo "❌ No text found in clipboard"
  exit 1
fi

# Ask Ollama to summarize commits
RESPONSE=$(ollama run llama3 <<EOF
You are an assistant that rewrites git commit messages into a short daily update for a client.
Here are the commits:
$COMMITS

Please write a 2–3 sentence summary update.
EOF
)

# Show result
echo "👉 Client Update:"
echo "$RESPONSE"

# Copy back to clipboard
echo -n "$RESPONSE" | xclip -selection clipboard
echo "✅ Summary copied to clipboard!"
