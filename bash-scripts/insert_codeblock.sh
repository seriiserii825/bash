#!/bin/bash

# Get clipboard content
content=$(xclip -selection clipboard -o)

# Wrap in triple backticks with proper line breaks
wrapped=$(cat <<EOF
\`\`\`bash
${content}
\`\`\`
EOF
)

# Copy back to clipboard
echo "$wrapped" | xclip -selection clipboard -i

echo "Clipboard content wrapped and updated."
