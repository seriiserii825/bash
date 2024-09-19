#!/bin/bash

read -p "Enter a word: " word
read -p "Enter file_type: " file_type

# exclude node_modules and .git
# exclude dist/main-hash.js
# exclude files with min.js
grep --color=always -Rnw . -e $word --exclude-dir={node_modules,.git} --exclude=dist/main-*.js --exclude=*min.js --include=*.$file_type
# grep --color=always -Rnw . -e $word  --include=*.$file_type
