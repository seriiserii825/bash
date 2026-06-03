#!/usr/bin/env bash

# Colors to use
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

IP_FILE="/tmp/vps_ip.txt"
SERVERS_CSV="/home/serii/Documents/python/py-private/servers.csv"

get_clipboard() {
  if command -v xclip &>/dev/null; then
    xclip -selection clipboard -o 2>/dev/null
  elif command -v xsel &>/dev/null; then
    xsel --clipboard --output 2>/dev/null
  elif command -v wl-paste &>/dev/null; then
    wl-paste 2>/dev/null
  else
    echo ""
  fi
}

is_valid_url() {
  local url="$1"
  # Accept: http(s)://domain, or bare domain.tld (with optional path)
  echo "$url" | grep -qiE '^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}(/.*)?$'
}

extract_domain() {
  local url="$1"
  # Strip protocol and path, keep domain
  domain=$(echo "$url" | sed -E 's|https?://||; s|/.*||; s|^www\.||')
  echo "$domain"
}

find_ip() {
  local domain="$1"
  echo -e "\n${CYAN}Resolving domain:${RESET} ${BOLD}$domain${RESET}"

  local ip
  ip=$(nslookup "$domain" 2>/dev/null | awk '/^Address:/ && !/#/ { print $2; exit }')

  if [[ -z "$ip" ]]; then
    echo -e "${RED}Could not resolve IP for $domain${RESET}"
    exit 1
  fi

  echo "$ip" > "$IP_FILE"
  echo -e "${GREEN}IP found:${RESET} ${BOLD}$ip${RESET}"

  check_servers "$ip"
}

check_servers() {
  local ip="$1"
  echo -e "${YELLOW}────────────────────────────────${RESET}"

  if [[ ! -f "$SERVERS_CSV" ]]; then
    echo -e "${RED}servers.csv not found: $SERVERS_CSV${RESET}"
    echo -e "${YELLOW}────────────────────────────────${RESET}"
    return
  fi

  local matches
  matches=$(awk -F',' -v ip="$ip" 'NR>1 && $3==ip { print }' "$SERVERS_CSV")

  if [[ -z "$matches" ]]; then
    echo -e "${RED}Not found in your servers${RESET}"
  else
    echo -e "${GREEN}Found in your servers:${RESET}"
    echo -e "${CYAN}  NAME                IP${RESET}"
    while IFS=',' read -r name _user ip_col _pass _port; do
      printf "  ${BOLD}%-20s${RESET} %s\n" "$name" "$ip_col"
    done <<< "$matches"
  fi

  echo -e "${YELLOW}────────────────────────────────${RESET}\n"
}

get_info() {
  local ip
  ip=$(cat "$IP_FILE" 2>/dev/null)

  if [[ -z "$ip" ]]; then
    echo -e "${RED}No IP found. Restart the script.${RESET}"
    return
  fi

  echo -e "\n${CYAN}IP info for${RESET} ${BOLD}$ip${RESET}"
  echo -e "${YELLOW}────────────────────────────────${RESET}"
  curl -s "https://ipinfo.io/$ip" | python3 -m json.tool 2>/dev/null || curl -s "https://ipinfo.io/$ip"
  echo -e "${YELLOW}────────────────────────────────${RESET}\n"
}

show_related() {
  local ip
  ip=$(cat "$IP_FILE" 2>/dev/null)

  if [[ -z "$ip" ]]; then
    echo -e "${RED}No IP found. Restart the script.${RESET}"
    return
  fi

  echo -e "\n${CYAN}Sites hosted on${RESET} ${BOLD}$ip${RESET} ${CYAN}(reverse IP lookup)${RESET}"
  echo -e "${YELLOW}────────────────────────────────${RESET}"
  local result
  result=$(curl -s "https://api.hackertarget.com/reverseiplookup/?q=$ip")

  if echo "$result" | grep -qi "error\|API count exceeded\|no records found"; then
    echo -e "${RED}$result${RESET}"
  else
    echo "$result" | nl -ba
  fi
  echo -e "${YELLOW}────────────────────────────────${RESET}\n"
}

show_menu() {
  local ip
  ip=$(cat "$IP_FILE" 2>/dev/null)
  echo -e "${BOLD}${CYAN}VPS Hosting Checker${RESET} — IP: ${GREEN}${ip}${RESET}"
  echo -e "${YELLOW}────────────────────${RESET}"
  echo -e "  ${BOLD}1.${RESET} Get info"
  echo -e "  ${BOLD}2.${RESET} Show related sites"
  echo -e "  ${BOLD}3.${RESET} Exit"
  echo -e "${YELLOW}────────────────────${RESET}"
}

# ── Main ──────────────────────────────────────────────────────────────────────

URL=$(get_clipboard | tr -d '[:space:]')

if [[ -z "$URL" ]]; then
  echo -e "${RED}Clipboard is empty.${RESET}"
  exit 1
fi

if ! is_valid_url "$URL"; then
  echo -e "${RED}Clipboard does not contain a valid URL:${RESET} $URL"
  exit 1
fi

echo -e "${CYAN}URL from clipboard:${RESET} ${BOLD}$URL${RESET}"
DOMAIN=$(extract_domain "$URL")
find_ip "$DOMAIN"

while true; do
  show_menu
  read -rp "Select: " choice
  echo

  case "$choice" in
    1) get_info ;;
    2) show_related ;;
    3) echo -e "${GREEN}Bye.${RESET}"; break ;;
    *) echo -e "${RED}Invalid option.${RESET}\n" ;;
  esac
done
