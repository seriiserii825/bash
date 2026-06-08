#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/libs/fzf-multiselect.sh"

REDIS_PATTERN="${REDIS_PATTERN:-sessions:*}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"
CURRENT_KEY=""
KEYS_CACHE=""

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
  _redis --raw KEYS "$REDIS_PATTERN" || true
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
    (( ++i )) || true
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

_view_key() {
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

_delete_current() {
  printf "${YELLOW}Delete '${BOLD}%s${RESET}${YELLOW}'? [y/N]: ${RESET}" "$CURRENT_KEY"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    _redis DEL "$CURRENT_KEY" > /dev/null
    printf "${RED}Deleted: %s${RESET}\n" "$CURRENT_KEY"
    CURRENT_KEY=""
    return 1
  else
    echo "Cancelled"
  fi
}

_do_select_key() {
  KEYS_CACHE=$(_keys_rich)
  local line key
  line=$(printf '%s\n' "$KEYS_CACHE" | fzf --prompt="Select key > " --height=50% --no-sort)
  key=$(awk '{print $NF}' <<< "$line")
  if [[ -n "$key" ]]; then
    _clipboard_copy "$key"
    CURRENT_KEY="$key"
    _view_key
    _time_end
  else
    echo "No key selected"
  fi
}

_do_delete_keys() {
  KEYS_CACHE=$(_keys_rich)
  local selected keys=()
  selected=$(printf '%s\n' "$KEYS_CACHE" | fzf_multiselect --prompt="Select keys to delete > " --height=50% --no-sort)

  [[ -z "$selected" ]] && { echo "No keys selected"; return; }

  while IFS= read -r line; do
    keys+=( "$(awk '{print $NF}' <<< "$line")" )
  done <<< "$selected"

  printf "${YELLOW}Delete ${BOLD}%d${RESET}${YELLOW} key(s)?${RESET}\n" "${#keys[@]}"
  for k in "${keys[@]}"; do printf "  ${CYAN}%s${RESET}\n" "$k"; done
  printf "${YELLOW}[y/N]: ${RESET}"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    _redis DEL "${keys[@]}" > /dev/null
    printf "${RED}Deleted %d key(s)${RESET}\n" "${#keys[@]}"
    [[ " ${keys[*]} " == *" $CURRENT_KEY "* ]] && CURRENT_KEY=""
  else
    echo "Cancelled"
  fi
}

_inner_menu() {
  while true; do
    echo ""
    echo "========================================"
    printf "  Key: ${CYAN}${BOLD}%s${RESET}\n" "$CURRENT_KEY"
    echo "========================================"
    echo "  1) Delete key"
    echo "  2) Back"
    echo "  0) Exit"
    echo "========================================"
    printf "Choice: "
    read -r choice

    case "$choice" in
      1) _delete_current || return ;;
      2) return ;;
      0|exit|q|quit) echo "Bye."; exit 0 ;;
      *) echo "Unknown option: $choice" ;;
    esac
  done
}

_main_menu() {
  while true; do
    echo ""
    echo "========================================"
    echo "  Redis CLI"
    echo "========================================"
    echo "  1) Select key"
    echo "  2) Delete key(s)"
    echo "  0) Exit"
    echo "========================================"
    printf "Choice: "
    read -r choice

    case "$choice" in
      1)
        _do_select_key
        [[ -n "$CURRENT_KEY" ]] && _inner_menu
        ;;
      2) _do_delete_keys ;;
      0|exit|q|quit) echo "Bye."; exit 0 ;;
      *) echo "Unknown option: $choice" ;;
    esac
  done
}

_print_keys() {
  KEYS_CACHE=$(_keys_rich)
  if [[ -z "$KEYS_CACHE" ]]; then
    printf "${YELLOW}No keys found (pattern: ${BOLD}%s${RESET}${YELLOW})${RESET}\n" "$REDIS_PATTERN"
    exit 0
  fi
  echo ""
  printf "${GRAY}────────────────────────────────────────${RESET}\n"
  printf " ${GRAY}Pattern: ${RESET}${CYAN}%s${RESET}\n" "$REDIS_PATTERN"
  printf "${GRAY}────────────────────────────────────────${RESET}\n"
  printf '%s\n' "$KEYS_CACHE"
  printf "${GRAY}────────────────────────────────────────${RESET}\n"
}

_print_keys
_main_menu
