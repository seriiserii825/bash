function getProjectPort (){
  # current_dir where was executed the script the roote where is .git but not full path, just dirname
  # current_dir=$(dirname "${BASH_SOURCE[0]}")
  local full_path
  full_path=$(git rev-parse --show-toplevel)
  local project_name
  project_name=$(basename "$full_path")
  local file_path="$(dirname "${BASH_SOURCE[0]}")/../csv/projects_ports.csv"
  local port=""
  while IFS=, read -ra cols; do
    if [[ "${cols[1]}" == "$project_name" ]]; then
      port="${cols[0]}"
      break
    fi
  done < "$file_path"
  if [[ -n "$port" ]]; then
    echo "$port"
  else
    echo "false" >&2
  fi
}
