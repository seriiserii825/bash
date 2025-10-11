#!/usr/bin/env bash
# Arch pkg helper (looped menu)
# - Show foreign (Qm)
# - Remove by regex pattern
# - Unified search (pacman + yay[AUR]) with install prompt
# Exit only via "EXIT"

set -euo pipefail

err()  { printf "\e[31m%s\e[0m\n" "$*" >&2; }
note() { printf "\e[33m%s\e[0m\n" "$*"; }
ok()   { printf "\e[32m%s\e[0m\n" "$*"; }
info() { printf "\e[36m%s\e[0m\n" "$*"; }

command -v pacman >/dev/null 2>&1 || { err "pacman not found"; exit 1; }

has_yay=false
if command -v yay >/dev/null 2>&1; then has_yay=true; fi

show_qm() {
  info "Foreign (AUR) packages (pacman -Qm):"
  if ! pacman -Qm 2>/dev/null | sed 's/^/  • /'; then
    echo "  (none)"
  fi
}

remove_by_pattern() {
  read -rp "Enter package prefix or regex (e.g. vlc-plugin-): " pattern
  [[ -z "$pattern" ]] && { err "Empty input"; return; }
  [[ "$pattern" =~ -$ ]] && pattern="${pattern}.+"
  local regex="^${pattern}$"

  info "Searching installed packages matching regex: $regex"
  mapfile -t PKGS < <(pacman -Qq | grep -E "$regex" || true)
  (( ${#PKGS[@]} == 0 )) && { err "No packages found."; return; }

  echo "Found packages:"
  printf '  • %s\n' "${PKGS[@]}"

  read -rp "Proceed to REMOVE these packages with 'pacman -Rns'? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Cancelled."; return; }

  printf '%s\n' "${PKGS[@]}" | sudo xargs -r pacman -Rns --
  ok "Removal complete."
}

# -------- Unified search + install ----------
# Collects results from pacman -Ss and yay -Ss (if present)
# Presents merged list, then installs via pacman (repo) or yay (AUR)
unified_search_install() {
  read -rp "Search query (name/keyword): " q
  [[ -z "$q" ]] && { err "Empty query"; return; }

  declare -a ROWS=()    # elements: "SRC|REPO|PKG|DESC"
  declare -A SEEN=()    # key "REPO|PKG" to dedup

  # Parse pacman -Ss output
  # Format: repo/pkg version [installed] ...
  #         <4-spaces> description
  info "Searching official repos: pacman -Ss \"$q\""
  local line repo pkg desc
  local prev_pkg_key=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^([a-z0-9\-]+)/([^[:space:]]+)[[:space:]] ]]; then
      repo="${BASH_REMATCH[1]}"
      pkg="${BASH_REMATCH[2]}"
      prev_pkg_key="$repo|$pkg"
      # initialize with empty desc; fill on next indented line if present
      if [[ -z "${SEEN[$prev_pkg_key]+x}" ]]; then
        ROWS+=("PACMAN|$repo|$pkg|")
        SEEN[$prev_pkg_key]=1
      fi
    elif [[ "$line" =~ ^[[:space:]]{2,}(.+) ]] && [[ -n "$prev_pkg_key" ]]; then
      # description line
      desc="${BASH_REMATCH[1]}"
      # update last ROW's desc if it matches prev_pkg_key
      for i in "${!ROWS[@]}"; do
        IFS='|' read -r SRC R RE P D <<<"${ROWS[$i]}"
        if [[ "$R|$P" == "$prev_pkg_key" && -z "$D" ]]; then
          ROWS[$i]="$SRC|$R|$P|$desc"
          break
        fi
      done
    fi
  done < <(pacman -Ss "$q" || true)

  # Parse yay -Ss if available (searches repos + AUR)
  if $has_yay; then
    info "Searching AUR & repos: yay -Ss \"$q\""
    prev_pkg_key=""
    while IFS= read -r line; do
      # yay formats: aur/pkg ...   or repo/pkg ...
      if [[ "$line" =~ ^([a-z0-9\-]+)/([^[:space:]]+)[[:space:]] ]]; then
        repo="${BASH_REMATCH[1]}"
        pkg="${BASH_REMATCH[2]}"
        prev_pkg_key="$repo|$pkg"
        # For AUR entries, repo will be 'aur'
        if [[ -z "${SEEN[$prev_pkg_key]+x}" ]]; then
          ROWS+=("YAY|$repo|$pkg|")
          SEEN[$prev_pkg_key]=1
        fi
      elif [[ "$line" =~ ^[[:space:]]{2,}(.+) ]] && [[ -n "$prev_pkg_key" ]]; then
        desc="${BASH_REMATCH[1]}"
        for i in "${!ROWS[@]}"; do
          IFS='|' read -r SRC R E P D <<<"${ROWS[$i]}"
          # shellcheck disable=SC2034
          if [[ "$R|$P" == "$prev_pkg_key" && -z "$D" ]]; then
            ROWS[$i]="$SRC|$R|$E|$desc"
            break
          fi
        done
      fi
    done < <(yay -Ss "$q" || true)
  else
    note "yay not found — AUR results skipped. Install: sudo pacman -S yay"
  fi

  (( ${#ROWS[@]} == 0 )) && { err "No results."; return; }

  echo
  echo "Results:"
  local idx=1
  for row in "${ROWS[@]}"; do
    IFS='|' read -r SRC REPO PKG DESC <<<"$row"
    [[ -z "$DESC" ]] && DESC="(no description)"
    printf "%2d) [%s] %s/%s — %s\n" "$idx" "$SRC" "$REPO" "$PKG" "$DESC"
    ((idx++))
  done

  echo
  read -rp "Choose number to install (or ENTER to cancel): " pick
  [[ -z "$pick" ]] && { echo "Cancelled."; return; }
  if ! [[ "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#ROWS[@]} )); then
    err "Invalid choice."; return;
  fi

  local choice="${ROWS[$((pick-1))]}"
  IFS='|' read -r SRC REPO PKG DESC <<<"$choice"

  echo
  info "Selected: [$SRC] $REPO/$PKG"
  if [[ "$REPO" == "aur" || "$SRC" == "YAY" ]]; then
    $has_yay || { err "yay not available to install AUR packages."; return; }
    read -rp "Install via yay: '$PKG'? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { echo "Cancelled."; return; }
    yay -S "$PKG"
  else
    read -rp "Install via pacman: '$PKG'? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { echo "Cancelled."; return; }
    sudo pacman -S "$PKG"
  fi
  ok "Done."
}

main_menu() {
  while true; do
    echo
    echo "====== PACKAGE MENU ======"
    echo "1) Show foreign (AUR) packages (pacman -Qm)"
    echo "2) Remove packages by pattern"
    echo "3) Unified search (pacman + AUR) and install"
    echo "EXIT) Exit program"
    echo "=========================="
    read -rp "Choose: " choice

    case "$choice" in
      1) show_qm ;;
      2) remove_by_pattern ;;
      3) unified_search_install ;;
      EXIT|exit|q|Q) echo "👋 Bye!"; break ;;
      *) echo "Invalid choice." ;;
    esac
  done
}

main_menu
