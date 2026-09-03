#!/bin/bash

# --- 1. Check MP3 files in current dir ---
mapfile -t MP3_FILES < <(find . -maxdepth 1 -name "*.mp3" | sort)

if [[ ${#MP3_FILES[@]} -eq 0 ]]; then
    echo "Error: no MP3 files found in current directory ($(pwd))."
    exit 1
fi

# --- 2. Clipboard ---
CLIP=$(xclip -selection clipboard -o 2>/dev/null) || true

# =============================================================
# Formats registry.
# Each format needs:
#   - an entry in FORMATS (id)
#   - an entry in FORMAT_DESC[id] (example shown in errors)
#   - a match_format_<id> function: prints matching lines from $1, or nothing
#   - a parse_format_<id> function: fills global TIMES/TITLES arrays from matched lines in $1
# To add a new format, just add all four pieces.
# =============================================================

FORMATS=(classic plain)

declare -A FORMAT_DESC=(
    [classic]='01. Галина ( 00:00 )
02. Трактористка ( 04:54 )
03. Закружился снег шальной ( 08:45 )'
    [plain]='01. Кабриолет 00:00
02. Вояж 02:43
03. В Питере — пить 06:23'
)

# --- Convert M:SS or H:MM:SS → HH:MM:SS ---
normalize_time() {
    local t="$1"
    IFS=':' read -ra p <<< "$t"
    if [[ ${#p[@]} -eq 2 ]]; then
        printf "%02d:%02d:%02d" 0 "$((10#${p[0]}))" "$((10#${p[1]}))"
    else
        printf "%02d:%02d:%02d" "$((10#${p[0]}))" "$((10#${p[1]}))" "$((10#${p[2]}))"
    fi
}

# --- Format: classic ("01. Title ( 00:00 )") ---
match_format_classic() {
    echo "$1" | grep -E '^[0-9]+\.[[:space:]]+.+\([[:space:]]*[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*\)[[:space:]]*$'
}

parse_format_classic() {
    local lines="$1"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local num time title
        num=$(echo "$line" | grep -oE '^[0-9]+')
        time=$(echo "$line" | grep -oE '[0-9]+:[0-9]{2}(:[0-9]{2})?')
        title=$(echo "$line" | sed -E 's/^[0-9]+\.[[:space:]]*//; s/[[:space:]]*\([[:space:]]*[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*\)[[:space:]]*$//')
        TIMES+=("$(normalize_time "$time")")
        TITLES+=("$(printf "%02d - %s" "$((10#$num))" "$title")")
    done <<< "$lines"
}

# --- Format: plain ("01. Title 00:00", no parentheses) ---
match_format_plain() {
    echo "$1" | grep -E '^[0-9]+\.[[:space:]]+.+[[:space:]]+[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*$'
}

parse_format_plain() {
    local lines="$1"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local num time title
        num=$(echo "$line" | grep -oE '^[0-9]+')
        time=$(echo "$line" | grep -oE '[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*$' | tr -d '[:space:]')
        title=$(echo "$line" | sed -E 's/^[0-9]+\.[[:space:]]*//; s/[[:space:]]+[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]*$//')
        TIMES+=("$(normalize_time "$time")")
        TITLES+=("$(printf "%02d - %s" "$((10#$num))" "$title")")
    done <<< "$lines"
}

# --- Detect which format(s) match the clipboard ---
declare -A MATCHED_LINES
MATCHED_FORMATS=()

for fmt in "${FORMATS[@]}"; do
    lines=$("match_format_${fmt}" "$CLIP") || true
    if [[ -n "$lines" ]]; then
        MATCHED_LINES[$fmt]="$lines"
        MATCHED_FORMATS+=("$fmt")
    fi
done

print_all_formats() {
    echo "Available formats:"
    for fmt in "${FORMATS[@]}"; do
        echo ""
        echo "[$fmt]"
        echo "${FORMAT_DESC[$fmt]}"
    done
}

if [[ ${#MATCHED_FORMATS[@]} -eq 0 ]]; then
    echo "Error: no timestamps found in clipboard matching any known format."
    echo ""
    print_all_formats
    exit 1
fi

if [[ ${#MATCHED_FORMATS[@]} -gt 1 ]]; then
    echo "Error: clipboard matches more than one format: ${MATCHED_FORMATS[*]}"
    echo ""
    print_all_formats
    exit 1
fi

FORMAT="${MATCHED_FORMATS[0]}"
TIMESTAMPS="${MATCHED_LINES[$FORMAT]}"

# --- 3. Select MP3 with fzf ---
MP3=$(printf '%s\n' "${MP3_FILES[@]}" \
    | fzf --prompt="Select MP3: " --height=40% --border --preview='echo {}')

if [[ -z "$MP3" ]]; then
    echo "No file selected. Exiting."
    exit 1
fi

# --- Build arrays ---
declare -a TIMES TITLES
"parse_format_${FORMAT}" "$TIMESTAMPS"

echo "Detected format: $FORMAT"
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
