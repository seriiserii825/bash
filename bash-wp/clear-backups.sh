#!/bin/bash

SITES_DIR="/home/$USER/Local Sites"

if [ ! -d "$SITES_DIR" ]; then
    echo "Directory not found: $SITES_DIR"
    exit 1
fi

remove_section() {
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
    total=$(du -shc "${items[@]}" 2>/dev/null | tail -1 | cut -f1)
    echo "Total: $total"
    echo ""

    read -p "Remove all $label? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for item in "${items[@]}"; do
            rm -rf "$item" && echo "Removed: $item"
        done
        echo ""
        echo "Done."
    else
        echo "Skipped."
    fi
    echo ""
}

mapfile -t wpress < <(find "$SITES_DIR" -name "*.wpress" 2>/dev/null)
mapfile -t node_modules < <(find "$SITES_DIR" -type d -name "node_modules" -prune 2>/dev/null)

remove_section ".wpress backups" "${wpress[@]}"
remove_section "node_modules" "${node_modules[@]}"
