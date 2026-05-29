#!/bin/bash
# Lists all JPG files in current directory with their width×height dimensions

# lista all jpg files and show title width and height
for i in *.jpg; do
    echo -n "$i: "
    identify -format "%w x %h\n" "$i"
done

