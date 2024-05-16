### array

# Declare arrays for titles and texts
titles=()
texts=()

# Function to add an object to the arrays
add_object_to_array() {
  titles+=("$1")
  texts+=("$2")
}

# sum array
local all_plugins=("${local_plugins[@]}" "${server_plugins[@]}")

# diff 2 arrays
local all_plugins=("${local_plugins[@]}" "${server_plugins[@]}")
local installed_plugins=($(getInstalledPlugins))
local plugins_to_install=($(echo ${all_plugins[@]} ${installed_plugins[@]} | tr ' ' '\n' | sort | uniq -u))


# check in array
[[ ${result[*]} =~ "All" ]] && echo "${all_choices[@]}" || echo "${result[@]}"

# Example usage
add_object_to_array "Title1" "Text1"
add_object_to_array "Title2" "Text2"
add_object_to_array "Title3" "Text3"

# Print the array elements
for ((i = 0; i < ${#titles[@]}; i++)); do
  echo "Title: ${titles[i]}, Text: ${texts[i]}"
done

### 

os=('ubuntu' 'windows' 'kali')
echo "${os[@]}" # print all elements
echo "${!os[@]}" # print all indexes
echo "${#os[@]}" # print length of array

os[3]='mac' # add element at index 3
unset os[2] # remove element at index 2

# unassociative array
declare -A car
car[BMW]=i8
car[Toyota]=corolla
car[Mercedes]=c300

echo "${car[Toyota]}"

### associative
#!/bin/bash

# Declare an associative array
declare -A myArray

# Add objects to the array
myArray["key1"]="value1"
myArray["key2"]="value2"
myArray["key3"]="value3"

# Access and print values from the array
echo "Object 1: ${myArray["key1"]}"
echo "Object 2: ${myArray["key2"]}"
echo "Object 3: ${myArray["key3"]}"

# Return the array (you can iterate over it or use it as needed)
echo "All keys: ${!myArray[@]}"
echo "All values: ${myArray[@]}"

for i in "${!array[@]}"
do
  echo "key :" $i
  echo "value:" ${array[$i]}
done
