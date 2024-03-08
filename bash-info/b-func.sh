
function parseArray {
  result=()
  array=("$@")

  for data in "${array[@]}"
  do
    if [[ $data == "value" ]]; then
      result+=("value")
    fi
  done

  echo "${result[@]}"
}

array=("value" "value1")

parseArray "${array[@]}"
