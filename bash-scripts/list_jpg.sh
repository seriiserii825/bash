#!/bin/bash

# lista all jpg files and show title width and height
for i in *.jpg; do
    echo -n "$i: "
    identify -format "%w x %h\n" "$i"
done

