#!/bin/bash

dir_path=~/Sites/wp-projects;
cd $dir_path;
echo $(pwd);
echo $(ls);
LIST="$(find . -mindepth 1 -maxdepth 1 -type d)";
while test -n "$LIST"; do
    for D in $LIST; do
      cd $D;
      echo "===================== $D ====================="
      git pull;
      echo "=========================================="
      cd ..;
    done;
done
