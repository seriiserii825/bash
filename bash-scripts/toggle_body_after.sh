#!/bin/bash

if [ ! -f "src/scss/partials/base.scss" ]; then
    echo "${tmagenta}⚠️ File src/scss/partials/base.scss not found. Exiting...${treset}"
    exit 1
fi

FILE="src/scss/partials/base.scss"

# Regex: exact uncommented line (with any indentation)
TARGET_REGEX='^[[:space:]]*display: none;[[:space:]]*$'
# Regex: exact commented line (with any indentation)
COMMENTED_REGEX='^[[:space:]]*/\* display: none; \*/[[:space:]]*$'

if grep -Eq "$COMMENTED_REGEX" "$FILE"; then
    # 🔄 Uncomment: from "/* display: none; */" → "display: none;"
    sed -i 's/^[[:space:]]*\/\* display: none; \*\/[[:space:]]*$/    display: none;/' "$FILE"
    echo "${tgreen}🟠 Uncommented: display: none;${treset}"

elif grep -Eq "$TARGET_REGEX" "$FILE"; then
    # 🔄 Comment: from "display: none;" → "/* display: none; */"
    sed -i 's/^[[:space:]]*display: none;[[:space:]]*$/    \/* display: none; *\//' "$FILE"
    # small fix: correct escaped slashes
    sed -i 's@    \/\* display: none; \*\/@    /* display: none; */@' "$FILE"
    echo "${tgreen}🔵 Commented: display: none;${treset}"

else
    echo "${tmagenta}⚠️ Target line not found.${treset}"
fi
