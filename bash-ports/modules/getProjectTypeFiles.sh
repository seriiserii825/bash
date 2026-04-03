function getProjectTypeFiles() {
  local type="$1"
  local file_path="$(dirname "${BASH_SOURCE[0]}")/../csv/project_type.csv"
  local files=()

  while IFS=, read -ra cols; do
    if [[ "${cols[0]}" == "$type" ]]; then
      files=("${cols[@]:1}")
      break
    fi
  done < "$file_path"

  echo "${files[@]}"
}
