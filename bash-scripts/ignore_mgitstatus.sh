#!/bin/bash 
user=$(whoami)
clipboard=$(xsel -b)
file=~/Downloads/ignore_mgitstatus.txt
touch $file
echo $clipboard > $file
# after Untracked files add new line
sed -i 's/Untracked files/Untracked files\n/g' $file
# remove space at the beginning of the line
sed -i 's/^ //g' $file
# for each line in file remove ./ from the beginning
sed -i 's/^\.\///g' $file
# # for each line remove : Untracked files at the end
sed -i 's/: Untracked files//g' $file
cd
while IFS= read -r line
do
  if [ -n "$line" ]; then
    echo "line: $line"
    line="${line}"
    if [ -d $line ]; then
      cd $line
      git config --local mgitstatus.ignore true
      cd 
    else
      echo "Directory $line does not exist"
      exit
    fi
  fi
done < $file
rm $file
