#!/usr/bin/env bash

PREFS="${PREFS:-/home/serii/.config/google-chrome/Default/Preferences}"
PREFS_KEY='custom-emulated-device-list'
PREFS_PATH=".devtools.preferences[\"$PREFS_KEY\"]"

# ─── clipboard helpers ────────────────────────────────────────────────────────

clip_copy() {
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --input
    elif command -v wl-copy &>/dev/null; then
        wl-copy
    else
        echo "Error: install xclip, xsel, or wl-clipboard" >&2; exit 1
    fi
}

clip_paste() {
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard -o
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --output
    elif command -v wl-paste &>/dev/null; then
        wl-paste --no-newline
    else
        echo "Error: install xclip, xsel, or wl-clipboard" >&2; exit 1
    fi
}

# ─── guards ──────────────────────────────────────────────────────────────────

check_deps() {
    if ! command -v jq &>/dev/null; then
        echo "Error: 'jq' is required but not installed." >&2; exit 1
    fi
    if [[ ! -f "$PREFS" ]]; then
        echo "Error: Preferences file not found: $PREFS" >&2; exit 1
    fi
}

chrome_running() {
    pgrep -x "chrome|google-chrome|chromium" &>/dev/null
}

# ─── export ──────────────────────────────────────────────────────────────────

do_export() {
    check_deps

    value=$(jq -r "$PREFS_PATH" "$PREFS")

    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "Error: '$PREFS_KEY' not found in Preferences." >&2; exit 1
    fi

    # pretty-print for clipboard readability
    count=$(echo "$value" | jq 'length' 2>/dev/null || echo "?")
    echo "$value" | jq . | clip_copy

    echo "Exported $count device(s) to clipboard."
}

# ─── import ──────────────────────────────────────────────────────────────────

do_import() {
    check_deps

    clipboard=$(clip_paste)
    if [[ -z "$clipboard" ]]; then
        echo "Error: Clipboard is empty — copy device JSON first." >&2; exit 1
    fi

    if chrome_running; then
        echo "Chrome is running — killing all instances..."
        pkill -x "chrome|google-chrome|chromium"
        sleep 1
    fi

    # strip pretty-printing in case the user copied it that way
    if ! compact=$(echo "$clipboard" | jq -c . 2>/dev/null); then
        echo "Error: Clipboard does not contain valid JSON." >&2; exit 1
    fi

    # must be an array
    kind=$(echo "$compact" | jq -r 'type')
    if [[ "$kind" != "array" ]]; then
        echo "Error: Expected a JSON array for '$PREFS_KEY', got: $kind." >&2; exit 1
    fi

    # each element must look like a Chrome device object
    bad=$(echo "$compact" | jq 'any(.[]; (has("title") and has("screen") and has("modes")) | not)')
    if [[ "$bad" == "true" ]]; then
        echo "Error: Array items don't look like Chrome emulated-device objects." >&2
        echo "Each device must have at least: title, screen, modes." >&2
        exit 1
    fi

    # backup
    cp "$PREFS" "${PREFS}.bak"

    # write back as a JSON-encoded string (Chrome stores it that way)
    tmp=$(mktemp)
    jq --arg val "$compact" "$PREFS_PATH = \$val" "$PREFS" > "$tmp" \
        && mv "$tmp" "$PREFS" \
        || { echo "Error: Failed to write Preferences." >&2; rm -f "$tmp"; exit 1; }

    count=$(echo "$compact" | jq 'length')
    echo "Imported $count device(s) into '$PREFS_KEY'."
    echo "Backup saved to ${PREFS}.bak"
}

# ─── main ────────────────────────────────────────────────────────────────────

ask_action() {
    printf "export\nimport" | fzf --prompt="action > " --height=5 --no-info
}

action="${1:-}"
if [[ -z "$action" ]]; then
    action=$(ask_action)
fi

case "$action" in
    export) do_export ;;
    import) do_import ;;
    *)
        echo "Usage: $(basename "$0") [export|import]"
        echo ""
        echo "  export   Copy $PREFS_KEY from Preferences to clipboard"
        echo "  import   Read $PREFS_KEY from clipboard and update Preferences"
        exit 1
        ;;
esac
