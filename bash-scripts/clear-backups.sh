#!/bin/bash
# Removes .wpress backups and node_modules from ~/Local Sites with size summary

SITES_DIR="/home/$USER/Local Sites"

if [ ! -d "$SITES_DIR" ]; then
    echo "Directory not found: $SITES_DIR"
    exit 1
fi

list_section() {
    local label="$1"
    shift
    local items=("$@")

    if [ ${#items[@]} -eq 0 ]; then
        echo "No $label found."
        echo ""
        return
    fi

    echo "Found ${#items[@]} $label:"
    echo ""
    for item in "${items[@]}"; do
        size=$(du -sh "$item" 2>/dev/null | cut -f1)
        printf "  %s  %s\n" "$size" "$item"
    done
    echo ""
}

mapfile -t wpress < <(find "$SITES_DIR" -name "*.wpress" 2>/dev/null)
mapfile -t node_modules < <(find "$SITES_DIR" -type d -name "node_modules" -prune 2>/dev/null)

all_items=("${wpress[@]}" "${node_modules[@]}")

if [ ${#all_items[@]} -eq 0 ]; then
    echo "Nothing to remove."
    exit 0
fi

list_section ".wpress backups" "${wpress[@]}"
list_section "node_modules" "${node_modules[@]}"

total_gb=$(du -sc --block-size=1G "${all_items[@]}" 2>/dev/null | tail -1 | cut -f1)
echo "Total to be removed: ${total_gb} GB"
echo ""

read -p "Press Enter to remove all listed items, or Ctrl+C to cancel..."

for item in "${all_items[@]}"; do
    rm -rf "$item" && echo "Removed: $item"
done
echo ""
echo "Done."
