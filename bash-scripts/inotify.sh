#!/bin/bash

# Directory to monitor
directory="/home/$USER/Downloads"

# Store the list of files in the directory
files_before=$(ls "$directory")

while true; do
    # Sleep for some time before checking again (adjust as needed)
    sleep 2
    
    # Get the list of files in the directory again
    files_after=$(ls "$directory")
    
    # Compare the two lists to find new files
    new_files=$(comm -13 <(echo "$files_before" | sort) <(echo "$files_after" | sort))
    
    # If new files are found, do something
    if [ -n "$new_files" ]; then
        echo "New file(s) detected:"
        # check for file extension
        if [[ $new_files == *.jpg ]]; then
          rename -v 's/[\ \(\)\&]/-/g' *.jpg
          jpegoptim $new_files --strip-all --all-progressive -m 80
        fi
    else
        echo "No new files found."
    fi
    
    # Update the list of files for the next iteration
    files_before="$files_after"
done
