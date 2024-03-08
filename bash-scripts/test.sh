#!/bin/bash

source /home/serii/Documents/bash/bash-scripts/bash-libs/multipleSelect.sh

choices=( 'one' 'two' 'three' 'four' 'five' ) 
my_choices=($(multipleSelect "${choices[@]}"))
echo "You chose: ${my_choices[@]}"

