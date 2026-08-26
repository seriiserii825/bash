#!/bin/bash
# Wraps clipboard content in a Markdown code block with the specified language tag

# get argument for language
lang="$1"
if [ -z "$lang" ]; then
  lang="bash"  # Default to bash if no argument is provided
fi

# Get clipboard content
content=$(xclip -selection clipboard -o)

# Wrap in triple backticks with proper line breaks
wrapped=$(cat <<EOF
\`\`\`$lang
${content}
\`\`\`
EOF
)

# Copy back to clipboard
echo "$wrapped" | xclip -selection clipboard -i

echo "Clipboard content wrapped and updated."
