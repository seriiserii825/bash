#!/bin/bash

file_path="$HOME/Downloads/git-repos.txt"

# loop through all lines in file
while IFS= read -r line; do
    # skip empty lines
    [[ -z "$line" ]] && continue

    # check if line is a directory and a Git repo
    if [[ ! -d "$line/.git" ]]; then
        echo "Not a Git repository: $line"
        continue
    fi

    echo "==============================="
    echo "Processing repository: $line"
    echo "==============================="

    cd "$line" || continue

    # check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes in $line:"
        git status

        read -p "Do you want to commit and push? (y/n): " answer
        if [[ "$answer" == "y" ]]; then
            git add .
            read -p "Enter commit message: " commit_message
            git commit -m "$commit_message"
            git push --all
            echo "Changes pushed."
        else
            echo "Skipping push for $line."
        fi
    else
        echo "No uncommitted changes in $line."
    fi

    echo
    read -p "Press Enter to continue to next repo..."
    echo
done < "$file_path"
