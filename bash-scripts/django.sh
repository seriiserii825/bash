#! /bin/bash 

# choose dir with fzf
dir_path=$(find . -maxdepth 1 -type d | fzf)
cd $dir_path
python manage.py runserver
cd ..
