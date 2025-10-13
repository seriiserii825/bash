#!/usr/bin/env bash
# Arch pkg helper (looped menu)
# - Show foreign (Qm)
# - Show explicit official (QEN) and explicit foreign (QEM)
# - Remove with fzf (optional regex filter)
# - Unified search (pacman + AUR) with install prompt
# - Save explicit package lists to pacman.txt and eiwi.txt
# Exit via numbered "8) Exit"

set -euo pipefail

err()  { printf "\e[31m%s\e[0m\n" "$*" >&2; }
note() { printf "\e[33m%s\e[0m\n" "$*"; }
ok()   { printf "\e[32m%s\e[0m\n" "$*"; }
info() { printf "\e[36m%s\e[0m\n" "$*"; }

command -v pacman >/dev/null 2>&1 || { err "pacman not found"; exit 1; }
has_yay=false; command -v yay >/dev/null 2>&1 && has_yay=true
has_fzf=false; command -v fzf >/dev/null 2>&1 && has_fzf=true

show_qm() {
  info "Foreign (AUR) packages (pacman -Qm):"
  pacman -Qm 2>/dev/null | sed 's/^/  • /' || echo "  (none)"
}

show_qen() {
  read -rp "Filter regex for explicit OFFICIAL (ENTER=all): " rgx || true
  info "Explicit OFFICIAL packages (pacman -Qen):"
  if [[ -n "${rgx:-}" ]]; then
    pacman -Qen | grep -Ei -- "$rgx" | sed 's/^/  • /' || echo "  (none)"
  else
    pacman -Qen | sed 's/^/  • /' || echo "  (none)"
  fi
}

show_qem() {
  read -rp "Filter regex for explicit FOREIGN/AUR (ENTER=all): " rgx || true
  info "Explicit FOREIGN (AUR) packages (pacman -Qem):"
  if [[ -n "${rgx:-}" ]]; then
    pacman -Qem | grep -Ei -- "$rgx" | sed 's/^/  • /' || echo "  (none)"
  else
    pacman -Qem | sed 's/^/  • /' || echo "  (none)"
  fi
}

remove_with_fzf() {
  $has_fzf || { err "fzf not found. Install: sudo pacman -S fzf"; return; }

  read -rp "Regex filter for installed packages (ENTER=all): " rgx || true
  mapfile -t ALL < <(pacman -Qq)
  if [[ -n "${rgx:-}" ]]; then
    mapfile -t LIST < <(printf '%s\n' "${ALL[@]}" | grep -Ei -- "$rgx" || true)
  else
    LIST=("${ALL[@]}")
  fi
  ((${#LIST[@]})) || { err "No packages match filter."; return; }

  info "Select packages to REMOVE (TAB to toggle, ENTER to confirm):"
  sel=$(printf '%s\n' "${LIST[@]}" | fzf --multi --prompt='Remove > ' --height=80% --reverse) || {
    note "Cancelled."; return;
  }
  [[ -z "$sel" ]] && { note "Nothing selected."; return; }

  echo "You selected:"; printf '  • %s\n' $sel
  read -rp "Proceed with 'pacman -Rns' for ALL selected? [y/N] " yn
  [[ "$yn" =~ ^[Yy]$ ]] || { note "Cancelled."; return; }
  # shellcheck disable=SC2086
  sudo pacman -Rns -- $sel
  ok "Removal complete."
}

unified_search_install() {
  read -rp "Search query (name/keyword): " q
  [[ -z "$q" ]] && { err "Empty query"; return; }

  declare -a ROWS=()     # "SRC|REPO|PKG|DESC"
  declare -A SEEN=()     # key "REPO|PKG"

  info "Searching official repos: pacman -Ss \"$q\""
  local line repo pkg desc prev; prev=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^([a-z0-9\-]+)/([^[:space:]]+)[[:space:]] ]]; then
      repo="${BASH_REMATCH[1]}"; pkg="${BASH_REMATCH[2]}"; prev="$repo|$pkg"
      if [[ -z "${SEEN[$prev]+x}" ]]; then ROWS+=("PACMAN|$repo|$pkg|"); SEEN[$prev]=1; fi
    elif [[ "$line" =~ ^[[:space:]]{2,}(.+) ]] && [[ -n "$prev" ]]; then
      desc="${BASH_REMATCH[1]}"
      for i in "${!ROWS[@]}"; do
        IFS='|' read -r SRC R P D <<<"${ROWS[$i]}"
        if [[ "$R|$P" == "$prev" && -z "$D" ]]; then ROWS[$i]="$SRC|$R|$P|$desc"; break; fi
      done
    fi
  done < <(pacman -Ss "$q" || true)

  if $has_yay; then
    info "Searching AUR & repos: yay -Ss \"$q\""
    prev=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^([a-z0-9\-]+)/([^[:space:]]+)[[:space:]] ]]; then
        repo="${BASH_REMATCH[1]}"; pkg="${BASH_REMATCH[2]}"; prev="$repo|$pkg"
        if [[ -z "${SEEN[$prev]+x}" ]]; then ROWS+=("YAY|$repo|$pkg|"); SEEN[$prev]=1; fi
      elif [[ "$line" =~ ^[[:space:]]{2,}(.+) ]] && [[ -n "$prev" ]]; then
        desc="${BASH_REMATCH[1]}"
        for i in "${!ROWS[@]}"; do
          IFS='|' read -r SRC R P D <<<"${ROWS[$i]}"
          if [[ "$R|$P" == "$prev" && -z "$D" ]]; then ROWS[$i]="$SRC|$R|$P|$desc"; break; fi
        done
      fi
    done < <(yay -Ss "$q" || true)
  else
    note "yay not found — skipping AUR search (sudo pacman -S yay)"
  fi

  ((${#ROWS[@]})) || { err "No results."; return; }

  echo; echo "Results:"
  local i=1
  for row in "${ROWS[@]}"; do
    IFS='|' read -r SRC REPO PKG DESC <<<"$row"
    [[ -z "$DESC" ]] && DESC="(no description)"
    printf "%2d) [%s] %s/%s — %s\n" "$i" "$SRC" "$REPO" "$PKG" "$DESC"
    ((i++))
  done

  read -rp "Choose number to install (ENTER=cancel): " n
  [[ -z "$n" ]] && { note "Cancelled."; return; }
  [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#ROWS[@]} )) || { err "Invalid choice."; return; }

  IFS='|' read -r SRC REPO PKG DESC <<<"${ROWS[$((n-1))]}"
  echo; info "Selected: [$SRC] $REPO/$PKG"

  if [[ "$REPO" == "aur" || "$SRC" == "YAY" ]]; then
    $has_yay || { err "yay required to install AUR packages."; return; }
    read -rp "Install via yay '$PKG'? [y/N] " yn; [[ "$yn" =~ ^[Yy]$ ]] || { note "Cancelled."; return; }
    yay -S "$PKG"
  else
    read -rp "Install via pacman '$PKG'? [y/N] " yn; [[ "$yn" =~ ^[Yy]$ ]] || { note "Cancelled."; return; }
    sudo pacman -S "$PKG"
  fi
  ok "Done."
}

save_lists() {
  local packages_dir="$HOME/dotfiles/packages"
  [[ -d "$packages_dir" ]] || mkdir -p "$packages_dir" || { err "Failed to create $packages_dir"; return; }

  local pac_file="$packages_dir/pacman.txt"
  local eiwi_file="$packages_dir/eiwi.txt"   # как просили: список AUR/foreign

  info "Saving explicit OFFICIAL packages to $pac_file ..."
  mapfile -t OFF < <(pacman -Qenq | sort -f)
  printf "%s\n" "${OFF[@]}" > "$pac_file"

  info "Saving explicit AUR/FOREIGN packages to $eiwi_file ..."
  mapfile -t AUR < <(pacman -Qemq | sort -f)
  printf "%s\n" "${AUR[@]}" > "$eiwi_file"

  ok "Saved: $(wc -l < "$pac_file") to pacman.txt;  $(wc -l < "$eiwi_file") to eiwi.txt"
  note "Location: $packages_dir"
}

main_menu() {
  while true; do
    echo
    echo "====== PACKAGE MENU ======"
    echo "1) Show foreign (Qm)"
    echo "2) Show explicit OFFICIAL (QEN)"
    echo "3) Show explicit FOREIGN/AUR (QEM)"
    echo "4) Remove packages (fzf, optional regex)"
    echo "5) Unified search (pacman + AUR) and install"
    echo "6) Refresh databases (pacman/yay) & orphans list"
    echo "7) Save explicit lists (pacman.txt / eiwi.txt)"
    echo "8) Exit"
    echo "=========================="
    read -rp "Choose: " choice
    case "$choice" in
      1) show_qm ;;
      2) show_qen ;;
      3) show_qem ;;
      4) remove_with_fzf ;;
      5) unified_search_install ;;
      6)
        sudo pacman -Sy
        $has_yay && yay -Sy || true
        echo "Orphans:"; pacman -Qtdq 2>/dev/null | sed 's/^/  • /' || echo "  (none)"
        ;;
      7) save_lists ;;
      8) echo "👋 Bye!"; break ;;
      *) echo "Invalid choice." ;;
    esac
  done
}

main_menu
