source "$(dirname "${BASH_SOURCE[0]}")/getProjectTypeFiles.sh"
source "$(dirname "${BASH_SOURCE[0]}")/findPortInFile.sh"
source "$(dirname "${BASH_SOURCE[0]}")/getProjectPort.sh"
source "$(dirname "${BASH_SOURCE[0]}")/setProjectPort.sh"
function vueHandler() {
  local -a project_files
  read -ra project_files <<< "$(getProjectTypeFiles "vue")"
  local PORT=""
  for file in "${project_files[@]}"; do
    local result
    result=$(grep -m1 'PORT=' "$file" 2>/dev/null)
    if [[ -n "$result" ]]; then
      PORT="${result#*=}"
      break
    fi
  done
  if [[ -z "$PORT" ]]; then
    echo "Error: no PORT found in project files." >&2
    return 1
  fi
  local project_name
  project_name=$(basename "$(git rev-parse --show-toplevel)")
  PORT=$(setProjectPort "$PORT" "$project_name")
  echo "Vue project detected. Port: $PORT"
}
