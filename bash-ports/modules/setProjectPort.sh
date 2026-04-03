function setProjectPort() {
  local port="$1"
  local project="$2"
  local csv_path="$(dirname "${BASH_SOURCE[0]}")/../csv/projects_ports.csv"

  local used_ports=()
  local project_line=""
  local project_line_num=0
  local line_num=0

  while IFS=, read -r col_port col_project; do
    ((line_num++))
    [[ "$col_port" == "port" ]] && continue
    used_ports+=("$col_port")
    if [[ "$col_project" == "$project" ]]; then
      project_line="$col_port"
      project_line_num=$line_num
    fi
  done < "$csv_path"

  # in CSV — use existing port
  if [[ -n "$project_line" ]]; then
    echo "$project_line"
    return 0
  fi

  # not in CSV — find a free port and add it
  local new_port="$port"
  while [[ " ${used_ports[*]} " == *" $new_port "* ]]; do
    ((new_port++))
  done

  echo "$new_port,$project" >> "$csv_path"
  echo "$new_port"
}
