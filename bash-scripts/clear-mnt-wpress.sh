#!/bin/bash
# Keeps only the 8 newest .wpress backups per project folder under /mnt/Projects/<letter>/<project>
# Shows what will be removed and asks for confirmation before deleting.

PROJECTS_DIR="/mnt/Projects"
KEEP=10

if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Directory not found: $PROJECTS_DIR"
    exit 1
fi

to_remove=()

while IFS= read -r project_dir; do
    mapfile -t files < <(find "$project_dir" -maxdepth 1 -type f -name "*.wpress" -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2-)

    count=${#files[@]}
    if [ "$count" -le "$KEEP" ]; then
        continue
    fi

    for ((i = KEEP; i < count; i++)); do
        to_remove+=("${files[$i]}")
    done
done < <(find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type d)

if [ ${#to_remove[@]} -eq 0 ]; then
    echo "Nothing to remove, every project already has $KEEP or fewer backups."
    exit 0
fi

echo "Found ${#to_remove[@]} .wpress file(s) to remove (older than the newest $KEEP per project):"
echo ""
for item in "${to_remove[@]}"; do
    size=$(du -sh "$item" 2>/dev/null | cut -f1)
    printf "  %s  %s\n" "$size" "$item"
done
echo ""

total_gb=$(du -sc --block-size=1G "${to_remove[@]}" 2>/dev/null | tail -1 | cut -f1)
echo "Total to be removed: ${total_gb} GB"
echo ""

read -p "Press Enter to remove all listed files, or Ctrl+C to cancel..."

for item in "${to_remove[@]}"; do
    rm -f "$item" && echo "Removed: $item"
done
echo ""
echo "Done."
