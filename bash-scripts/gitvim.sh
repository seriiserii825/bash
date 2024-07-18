#!/bin/bash
# This script opens changed files from git into neovim

FOR_STATUS=
FOR_LOG=
COMMIT="HEAD"

open_in_vim () {
  if [[ ! -z $FOR_LOG ]]; then
    git show --pretty="" --name-only $COMMIT | xargs nvim
  else
    git status --porcelain | awk 'match ($1, "M") {print $2}' | xargs nvim -p
  fi
}

usage () {
cat << EOF
Usage: $0 OPTIONS

This script opens changed files from git into neovim.

OPTIONS:
   -s      Open currently modified tracked files
   -l      Open changed files from a commit
   -c      Specify which commit to use for -l (defaults to HEAD)

EOF
}

while getopts "hslc:" OPTION
do
  case $OPTION in
    h) usage; exit
      ;;
    s) FOR_STATUS=1
      ;;
    l) FOR_LOG=1
      ;;
    c) COMMIT=$OPTARG
      ;;
    ?) usage; exit
      ;;
  esac
done

open_in_vim
