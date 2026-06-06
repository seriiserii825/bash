#!/usr/bin/env bash

set -euo pipefail

REDIS_PATTERN="${REDIS_PATTERN:-sessions:*}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"
CURRENT_KEY=""

RESET='\033[0m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'

_redis() {
  local env_file="$PROJECT_DIR/.env"
  local password
  password=$(grep ^REDIS_PASSWORD "$env_file" 2>/dev/null | cut -d= -f2 | tr -d "\"'")
  if [[ -n "$password" ]]; then
    docker compose -f "$PROJECT_DIR/docker-compose.yaml" exec -T redis redis-cli -a "$password" --no-auth-warning "$@"
  else
    docker compose -f "$PROJECT_DIR/docker-compose.yaml" exec -T redis redis-cli "$@"
  fi
}

_keys() {
  _redis --raw KEYS "$REDIS_PATTERN"
}

_keys_rich() {
  local keys
  mapfile -t keys < <(_keys)
  [[ ${#keys[@]} -eq 0 ]] && return

  local values
  mapfile -t values < <(_redis --raw MGET "${keys[@]}")

  local i=0
  for key in "${keys[@]}"; do
    local val="${values[$i]}"
    local created browser os ip
    created=$(jq -r '.createdAt // "0000-00-00T00:00:00Z"' <<< "$val" 2>/dev/null)
    browser=$(jq -r '.metadata.device.browser // "-"'       <<< "$val" 2>/dev/null)
    os=$(     jq -r '.metadata.device.os      // "-"'       <<< "$val" 2>/dev/null)
    ip=$(     jq -r '.metadata.ip             // "-"'       <<< "$val" 2>/dev/null)
    printf '%s\t%s/%s\t%s\t%s\n' "$created" "$browser" "$os" "$ip" "$key"
    (( i++ ))
  done | sort -r | awk -F'\t' '{
    sub(/T/, " ", $1); sub(/:..\..+$/, "", $1)
    printf "%-17s  %-20s  %-16s  %s\n", $1, $2, $3, $4
  }'
}

_clipboard_copy() {
  printf '%s' "$1" | xclip -selection clipboard 2>/dev/null \
    || printf '%s' "$1" | xsel --clipboard --input 2>/dev/null \
    || printf '%s' "$1" | wl-copy 2>/dev/null \
    || { echo "Clipboard tool not found (xclip/xsel/wl-copy)"; return 1; }
}

_select_key() {
  local line key
  line=$(_keys_rich | fzf --prompt="Select key > " --height=50% --no-sort)
  key=$(awk '{print $NF}' <<< "$line")
  if [[ -n "$key" ]]; then
    _clipboard_copy "$key"
    CURRENT_KEY="$key"
    _view_key
  else
    echo "No key selected"
  fi
}

_view_key() {
  if [[ -z "$CURRENT_KEY" ]]; then
    printf "${YELLOW}No key selected${RESET}\n"
    return
  fi

  local raw
  raw=$(_redis --raw GET "$CURRENT_KEY" 2>/dev/null)

  if [[ -z "$raw" ]]; then
    printf "${RED}Key not found or empty${RESET}\n"
    return
  fi

  echo ""
  printf "${GRAY}────────────────────────────────────────${RESET}\n"
  printf " ${GRAY}Key  ${RESET}${CYAN}${BOLD}%s${RESET}\n" "$CURRENT_KEY"
  printf "${GRAY}────────────────────────────────────────${RESET}\n"
  echo "$raw" | jq -C . 2>/dev/null || printf "${YELLOW}%s${RESET}\n" "$raw"
  printf "${GRAY}────────────────────────────────────────${RESET}\n"
}

_time_end() {
  if [[ -z "$CURRENT_KEY" ]]; then
    echo "No key selected"
    return
  fi

  local ms
  ms=$(_redis --raw PTTL "$CURRENT_KEY" 2>/dev/null)

  if [[ "$ms" -lt 0 ]]; then
    case "$ms" in
      -1) printf "${YELLOW}Key '$CURRENT_KEY' has no expiry${RESET}\n" ;;
      -2) printf "${RED}Key '$CURRENT_KEY' does not exist${RESET}\n" ;;
      *)  printf "${RED}Unknown TTL: $ms${RESET}\n" ;;
    esac
    return
  fi

  local total_s=$(( ms / 1000 ))
  local d=$(( total_s / 86400 ))
  local h=$(( (total_s % 86400) / 3600 ))
  local m=$(( (total_s % 3600) / 60 ))
  local s=$(( total_s % 60 ))
  local expires_at
  expires_at=$(date -d "+${total_s} seconds" "+%Y-%m-%d %H:%M:%S")

  local time_color=$GREEN
  [[ $d -eq 0 && $h -lt 1 ]] && time_color=$RED
  [[ $d -eq 0 && $h -lt 24 && $h -ge 1 ]] && time_color=$YELLOW

  printf "${GRAY}Key:        ${RESET}${CYAN}%s${RESET}\n" "$CURRENT_KEY"
  printf "${GRAY}Remaining:  ${RESET}${time_color}%dd %02d:%02d:%02d${RESET}\n" "$d" "$h" "$m" "$s"
  printf "${GRAY}Expires at: ${RESET}${time_color}%s${RESET}\n" "$expires_at"
}

_delete_key() {
  if [[ -z "$CURRENT_KEY" ]]; then
    echo "No key selected"
    return
  fi

  printf "${YELLOW}Delete '${BOLD}%s${RESET}${YELLOW}'? [y/N]: ${RESET}" "$CURRENT_KEY"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    _redis DEL "$CURRENT_KEY" > /dev/null
    printf "${RED}Deleted: %s${RESET}\n" "$CURRENT_KEY"
    CURRENT_KEY=""
  else
    echo "Cancelled"
  fi
}

_print_menu() {
  echo ""
  echo "========================================"
  if [[ -n "$CURRENT_KEY" ]]; then
    printf "  Key: ${CYAN}${BOLD}%s${RESET}\n" "$CURRENT_KEY"
  else
    printf "  Key: ${GRAY}(none)${RESET}\n"
  fi
  echo "========================================"
  echo "  1) Select Key  (fzf → clipboard)"
  echo "  2) Time End    (TTL)"
  echo "  3) Delete Key"
  echo "  0) Exit"
  echo "========================================"
  printf "Choice: "
}

main() {
  _select_key
  while true; do
    _print_menu
    read -r choice

    case "$choice" in
      1) _select_key ;;
      2) _time_end ;;
      3) _delete_key ;;
      0|exit|q|quit) echo "Bye."; break ;;
      *) echo "Unknown option: $choice" ;;
    esac
  done
}

main
