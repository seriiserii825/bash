#!/bin/bash
# Contacts manager (khard): view, add from .vcf, delete

source /home/serii/dotfiles/zsh_modules/zsh_colors
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

C_RESET=$treset
CONTACTS_DIR="$HOME/.local/share/contacts/default"
KHARD_CONF="$HOME/.config/khard/khard.conf"

# check if khard is installed
if ! [ -x "$(command -v khard)" ]; then
  echo "khard is not installed. Installing..." >&2
  sudo pacman -S --needed khard || exit 1
fi

# khard refuses to run without a config
if ! [ -f "$KHARD_CONF" ]; then
  echo "Creating $KHARD_CONF"
  mkdir -p "$(dirname "$KHARD_CONF")" "$CONTACTS_DIR"
  cat > "$KHARD_CONF" <<EOF
[addressbooks]
[[default]]
path = $CONTACTS_DIR/

[general]
default_action = list
editor = nvim
merge_editor = nvim
EOF
fi

# "uid<TAB>name<TAB>addressbook" lines
function contactList() {
  khard list --parsable 2>/dev/null
}

function viewContacts() {
  contactList | fzf --delimiter='\t' --with-nth=2 \
    --prompt="View contact: " \
    --preview 'khard show uid:{1}' \
    --preview-window 'right:65%:wrap' >/dev/null
}

# Splits a .vcf (may contain several cards) into one file per card,
# adding a UID to cards that don't have one (khard ignores those)
function importVcf() {
  local file=$1
  awk -v dir="$CONTACTS_DIR" '
    /^BEGIN:VCARD/ { card = ""; uid = "" }
    { card = card $0 "\n" }
    /^UID:/ { uid = $0; sub(/^UID:/, "", uid); sub(/\r$/, "", uid) }
    /^END:VCARD/ {
      if (uid == "") {
        "uuidgen" | getline uid; close("uuidgen")
        sub(/\n/, "\nUID:" uid "\n", card)
      }
      out = dir "/" uid ".vcf"
      printf "%s", card > out; close(out)
      print "  + " out
    }
  ' "$file"
}

function addContacts() {
  selected=$(fd -e vcf . "$HOME/Downloads" "$PWD" 2>/dev/null | sort -u \
    | fzf_multiselect --prompt="Import .vcf: " --preview 'cat {}')
  [ -z "$selected" ] && echo "No files selected." && return
  mkdir -p "$CONTACTS_DIR"
  while IFS= read -r file; do
    echo "${tgreen}Importing $file${C_RESET}"
    importVcf "$file"
  done <<< "$selected"
}

function deleteContacts() {
  selected=$(contactList \
    | fzf_multiselect --delimiter='\t' --with-nth=2 \
      --prompt="Delete contacts: " \
      --preview 'khard show uid:{1}')
  [ -z "$selected" ] && echo "No contacts selected." && return
  echo "${tred}Will delete:${C_RESET}"
  cut -f2 <<< "$selected"
  read -rp "Confirm? [y/N] " answer
  [[ $answer != [yY] ]] && echo "Cancelled." && return
  cut -f1 <<< "$selected" | while IFS= read -r uid; do
    khard remove --force "uid:$uid"
  done
}

while true; do
  echo ""
  echo "${tgreen}1) View contacts${C_RESET}"
  echo "${tblue}2) Add contacts from .vcf (multi-select)${C_RESET}"
  echo "${tred}3) Delete contacts (multi-select)${C_RESET}"
  echo "4) Exit"

  read -rp "Select an option: " option
  case $option in
    1)
      viewContacts
      ;;
    2)
      addContacts
      ;;
    3)
      deleteContacts
      ;;
    4)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
