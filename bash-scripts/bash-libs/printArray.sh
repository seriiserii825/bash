function printArray() {
  local array=("$@")
  echo "${tgreen}Array size: ${#array[@]}${treset}"
  for (( i=0; i<${#array[@]}; i++ ))
  do
    echo "$i: ${array[$i]}"
  done
  # for i in "${array[@]}"; do
  #   echo "$i"
  # done
  echo "${tblue}End of array.${treset}"
}
