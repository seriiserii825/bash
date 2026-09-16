#!/bin/bash
# Interactive disk cleanup menu. Run without args for a menu, or pass indices
# directly, e.g.: clear-system.sh 1 3

SITES_DIR="/home/$USER/Local Sites"
TRASH_DIR="$HOME/.local/share/Trash/files"
NPM_CACHE_DIR="$HOME/.npm"
BUN_CACHE_DIR="$HOME/.bun/install/cache"
NVM_DIR="$HOME/.config/nvm"
TOOL_CACHES=(
    "$HOME/.cache/ms-playwright"
    "$HOME/.cache/google-chrome"
    "$HOME/.cache/yandex-browser"
    "$HOME/.cache/yarn"
    "$HOME/.cache/huggingface"
    "$HOME/.cache/yay"
    "$HOME/.cache/puppeteer"
    "$HOME/.cache/selenium"
    "$HOME/.cache/uv"
    "$HOME/.cache/mozilla"
)

# List existing items with sizes, confirm, then remove them.
confirm_and_remove() {
    local label="$1"
    shift
    local items=("$@")

    local existing=()
    for item in "${items[@]}"; do
        [ -e "$item" ] && existing+=("$item")
    done

    if [ ${#existing[@]} -eq 0 ]; then
        echo "Nothing to remove for: $label"
        return
    fi

    echo "Found for \"$label\":"
    echo ""
    for item in "${existing[@]}"; do
        size=$(du -sh "$item" 2>/dev/null | cut -f1)
        printf "  %s  %s\n" "$size" "$item"
    done
    echo ""

    total_gb=$(du -sc --block-size=1G "${existing[@]}" 2>/dev/null | tail -1 | cut -f1)
    echo "Total to be removed: ${total_gb} GB"
    echo ""

    read -p "Press Enter to remove, or Ctrl+C to cancel..."

    for item in "${existing[@]}"; do
        rm -rf "$item" && echo "Removed: $item"
    done
    echo ""
    echo "Done."
}

clean_trash() {
    mapfile -t items < <(find "$TRASH_DIR" -mindepth 1 -maxdepth 1 2>/dev/null)
    confirm_and_remove "Trash" "${items[@]}"
}

clean_npm_cache() {
    confirm_and_remove "npm cache" "$NPM_CACHE_DIR"
}

clean_bun_cache() {
    confirm_and_remove "bun cache" "$BUN_CACHE_DIR"
}

clean_tool_caches() {
    confirm_and_remove "misc tool caches (~/.cache)" "${TOOL_CACHES[@]}"
}

clean_node_modules() {
    if [ ! -d "$SITES_DIR" ]; then
        echo "Directory not found: $SITES_DIR"
        return
    fi
    mapfile -t items < <(find "$SITES_DIR" -type d -name "node_modules" -prune 2>/dev/null)
    confirm_and_remove "node_modules in Local Sites" "${items[@]}"
}

clean_old_node_versions() {
    export NVM_DIR
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1091
        \. "$NVM_DIR/nvm.sh"
    fi

    if ! command -v nvm >/dev/null 2>&1; then
        echo "nvm not found"
        return
    fi

    local current
    current=$(nvm current)

    mapfile -t old_dirs < <(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 -type d ! -name "$current" 2>/dev/null)

    if [ ${#old_dirs[@]} -eq 0 ]; then
        echo "No old Node.js versions found (current: $current)."
        return
    fi

    echo "Current active version: $current (kept)"
    echo ""
    confirm_and_remove "old Node.js versions" "${old_dirs[@]}"
}

show_menu() {
    cat <<EOF
Choose what to clean:

  1) Trash (~/.local/share/Trash)
  2) npm cache (~/.npm)
  3) bun cache (~/.bun/install/cache)
  4) Misc tool caches in ~/.cache (playwright, chrome, yandex-browser, yarn, huggingface, yay, puppeteer, selenium, uv, mozilla)
  5) node_modules in ~/Local Sites
  6) Old Node.js versions via nvm (keeps the currently active one)
  a) All of the above, one by one
  q) Quit

EOF
}

run_choice() {
    case "$1" in
        1) clean_trash ;;
        2) clean_npm_cache ;;
        3) clean_bun_cache ;;
        4) clean_tool_caches ;;
        5) clean_node_modules ;;
        6) clean_old_node_versions ;;
        a) for i in 1 2 3 4 5 6; do run_choice "$i"; echo ""; done ;;
        q) exit 0 ;;
        *) echo "Unknown choice: $1" ;;
    esac
}

if [ $# -gt 0 ]; then
    for arg in "$@"; do
        run_choice "$arg"
        echo ""
    done
    exit 0
fi

while true; do
    show_menu
    read -p "> " choice
    echo ""
    run_choice "$choice"
    echo ""
done
