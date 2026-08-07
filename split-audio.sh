#!/bin/bash

# --- 1. Check MP3 files in current dir ---
mapfile -t MP3_FILES < <(find . -maxdepth 1 -name "*.mp3" | sort)

if [[ ${#MP3_FILES[@]} -eq 0 ]]; then
    echo "Error: no MP3 files found in current directory ($(pwd))."
    exit 1
fi

# --- 2. Clipboard ---
CLIP=$(xclip -selection clipboard -o 2>/dev/null) || true

# --- Validate timestamps ---
TIMESTAMPS=$(echo "$CLIP" | grep -E '^[0-9]+\.[[:space:]]+.+\([[:space:]]*[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*\)[[:space:]]*$') || true

if [[ -z "$TIMESTAMPS" ]]; then
    echo "Error: no timestamps found in clipboard."
    echo ""
    echo "Expected format (one per line):"
    echo "  01. Галина ( 00:00 )"
    echo "  02. Трактористка ( 04:54 )"
    echo "  03. Закружился снег шальной ( 08:45 )"
    exit 1
fi

# --- 3. Select MP3 with fzf ---
MP3=$(printf '%s\n' "${MP3_FILES[@]}" \
    | fzf --prompt="Select MP3: " --height=40% --border --preview='echo {}')

if [[ -z "$MP3" ]]; then
    echo "No file selected. Exiting."
    exit 1
fi

# --- Convert M:SS or H:MM:SS → HH:MM:SS ---
normalize_time() {
    local t="$1"
    IFS=':' read -ra p <<< "$t"
    if [[ ${#p[@]} -eq 2 ]]; then
        printf "%02d:%02d:%02d" 0 "${p[0]}" "${p[1]}"
    else
        printf "%02d:%02d:%02d" "${p[0]}" "${p[1]}" "${p[2]}"
    fi
}

# --- Build arrays ---
declare -a TIMES TITLES
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    NUM=$(echo "$line" | grep -oE '^[0-9]+')
    TIME=$(echo "$line" | grep -oE '[0-9]+:[0-9]{2}(:[0-9]{2})?')
    TITLE=$(echo "$line" | sed -E 's/^[0-9]+\.[[:space:]]*//; s/[[:space:]]*\([[:space:]]*[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*\)[[:space:]]*$//')
    TIMES+=("$(normalize_time "$TIME")")
    TITLES+=("$(printf "%02d - %s" "$NUM" "$TITLE")")
done <<< "$TIMESTAMPS"

echo "Found ${#TIMES[@]} timestamps:"
for i in "${!TIMES[@]}"; do
    echo "  ${TIMES[$i]} — ${TITLES[$i]}"
done
echo ""

DIR=$(dirname "$MP3")
echo "File: $MP3"
echo "Output: $DIR"
echo ""

# --- Split ---
for i in "${!TIMES[@]}"; do
    START="${TIMES[$i]}"
    TITLE="${TITLES[$i]}"
    SAFE_TITLE="${TITLE//\//-}"
    OUTFILE="$DIR/${SAFE_TITLE}.mp3"

    if [[ $i -lt $(( ${#TIMES[@]} - 1 )) ]]; then
        END="${TIMES[$((i+1))]}"
        ffmpeg -i "$MP3" -ss "$START" -to "$END" -c copy "$OUTFILE" -y 2>/dev/null
    else
        ffmpeg -i "$MP3" -ss "$START" -c copy "$OUTFILE" -y 2>/dev/null
    fi

    echo "Created: $OUTFILE"
done

echo ""
echo "Done!"
