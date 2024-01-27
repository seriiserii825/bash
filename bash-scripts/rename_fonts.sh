#! /bin/bash 

args=("$@")

echo "Set 2 symbols like 'iT' or 'mI'"

if [ $# -eq 0 ]
then
    echo "No arguments supplied"
    exit 1
  else
    for i in "${args[@]}"
    do
      echo "Renaming $i"
      first=${i:0:1}
      last=${i:1:2}
      to="$first-$last"
      rename "s/$i/$to/" *
    done
fi
