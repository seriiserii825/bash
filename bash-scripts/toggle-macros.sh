#!/bin/bash

init_file_path="$HOME/.config/nvim/init.vim"

# chieck if line with python-macros.vim have comment ", than remove comment "

function commentPython(){
    sed -i 's/^\(\s*\)\(.*python-macros.vim\)/\1"\2/' "$init_file_path"
}

function uncommentPython(){
    sed -i 's/^\(\s*\)"\(.*python-macros.vim\)/\1\2/' "$init_file_path"
}

function commentBash(){
    sed -i 's/^\(\s*\)\(.*bash-macros.vim\)/\1"\2/' "$init_file_path"
}

function uncommentBash(){
    sed -i 's/^\(\s*\)"\(.*bash-macros.vim\)/\1\2/' "$init_file_path"
}

if grep -q '^\s*".*python-macros.vim' "$init_file_path"; then
    # Remove the comment from the line
    uncommentPython
    commentBash
    echo "Uncommented python-macros.vim in $init_file_path"
else
    # Add a comment to the line
    commentPython
    uncommentBash
    echo "Commented python-macros.vim in $init_file_path"
fi

