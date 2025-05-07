#! /bin/bash

echo "type a word"
read st1
echo ${st1,,}   # all lowercase
echo ${st1^} # Upper first letter
echo ${st1^^} # LOWER-WORD

