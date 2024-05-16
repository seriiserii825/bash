#! /bin/bash

echo "How much files you want to create: "
read num

re='^[0-9]+$'
if ! [[ $num =~ $re ]] ; then
   echo "error: Not a number" >&2; exit 1
fi

echo "Enter file name: "
read file

for (( i=1; i<="$num"; i++ ))
do
  item=$(printf '%02d' "$i")
  touch "$item-$file"
done
