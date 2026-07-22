#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need fzf
need rsync

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

quit() { echo "Exit."; exit 0; }

# Copies each source into $1 (destination dir). If a same-named file/folder
# already exists at the destination, appends "-YYYY-MM-DD_HH-MM-SS" instead of overwriting.
do_rsync() {
  local dest="$1"; shift
  local src base target name ext stamp
  stamp="$(date +%Y-%m-%d_%H-%M-%S)"

  for src in "$@"; do
    src="${src%/}"
    base="$(basename -- "$src")"
    target="$dest/$base"

    if [ -e "$target" ]; then
      if [[ "$base" == *.* && "$base" != .* ]]; then
        name="${base%.*}"
        ext="${base##*.}"
        target="$dest/${name}-${stamp}.${ext}"
      else
        target="$dest/${base}-${stamp}"
      fi
    fi

    echo "▶️  rsync -ah --info=progress2 --partial --inplace -- \"$src\" \"$target\""

    if [ -d "$src" ]; then
      mkdir -p -- "$target"
      rsync -ah --info=progress2 --partial --inplace --human-readable -- "$src/." "$target/"
    else
      rsync -ah --info=progress2 --partial --inplace --human-readable -- "$src" "$target"
    fi
  done
}

# ── 0. DIRECTION ─────────────────────────────────────────────────────────────
MODE=$(printf 'To folder (choose destination)\nFrom Downloads here\n🚪 Exit' \
  | fzf --height=40% --reverse --no-info \
        --header="Select transfer direction") || quit

[[ "$MODE" == "🚪"* ]] && quit

# ── 0B. FROM DOWNLOADS HERE ──────────────────────────────────────────────────
if [ "$MODE" = "From Downloads here" ]; then
  SRC_BASE="$HOME/Downloads"
  [ -d "$SRC_BASE" ] || { echo "❌ Folder '$SRC_BASE' not found."; exit 1; }
  export SRC_BASE
  DEST="$(pwd)"

  echo "🔎 Select files or folders from Downloads to send here:"
  mapfile -t SELECTED < <(
    find "$SRC_BASE" -mindepth 1 -maxdepth 1 -printf '%T@ %P\0' \
    | sort -rz -k1,1 \
    | sed -z 's/^[^ ]* //' \
    | fzf_multiselect --read0 --height=80% --reverse \
          --prompt="$SRC_BASE/ > " \
          --preview 'p="$SRC_BASE/{}"; if [ -d "$p" ]; then ls -la --color=always -- "$p"; else file -b -- "$p"; fi' \
          --preview-window=right,60%
  )

  [ "${#SELECTED[@]}" -gt 0 ] || quit

  SRCS=()
  for s in "${SELECTED[@]}"; do
    SRCS+=("$SRC_BASE/${s%/}")
  done

  echo "📦 Sources:"
  printf '   %s\n' "${SRCS[@]}"
  echo "🛬 Destination: $DEST"

  echo
  do_rsync "$DEST" "${SRCS[@]}"

  echo "✅ Done."
  exit 0
fi

# ── 1. BASE PATH ─────────────────────────────────────────────────────────────
BASE_CHOICE=$(printf '/mnt/Projects\nDownloads\nOther folder\n🚪 Exit' \
  | fzf --height=40% --reverse --no-info \
        --header="Select starting folder") || quit

[[ "$BASE_CHOICE" == "🚪"* ]] && quit

if [ "$BASE_CHOICE" = "Other folder" ]; then
  read -r -p "Enter path: " BASE_PATH
  BASE_PATH="${BASE_PATH%/}"
elif [ "$BASE_CHOICE" = "Downloads" ]; then
  BASE_PATH="$HOME/Downloads"
else
  BASE_PATH="/mnt/Projects"
fi

[ -d "$BASE_PATH" ] || { echo "❌ Folder '$BASE_PATH' not found."; exit 1; }

# ── 2. SEARCH METHOD ─────────────────────────────────────────────────────────
while true; do
  METHOD=$(printf 'Search by name\nBrowse with fzf\nFind path\n🚪 Exit' \
    | fzf --height=40% --reverse --no-info \
          --header="Select destination folder method  |  base: $BASE_PATH") || quit

  [[ "$METHOD" == "🚪"* ]] && quit

  if [ "$METHOD" = "Find path" ]; then
    read -r -p "Enter name to find (partial match): " QUERY
    [ -n "$QUERY" ] || continue

    mapfile -t RESULTS < <(find "$BASE_PATH" -mindepth 1 -type d -iname "*${QUERY}*" 2>/dev/null | sort)

    if [ "${#RESULTS[@]}" -eq 0 ]; then
      echo "❌ Nothing matching '$QUERY' in $BASE_PATH"
      read -r -p "Press Enter to return to menu…" _
      continue
    fi

    printf '%s\n' "${RESULTS[@]}"
    read -r -p "Press Enter to return to menu…" _
    continue
  fi

  break
done

# ── 3A. TEXT SEARCH ──────────────────────────────────────────────────────────
if [ "$METHOD" = "Search by name" ]; then
  read -r -p "Enter name (partial match): " QUERY
  [ -n "$QUERY" ] || quit

  DEST=$(find "$BASE_PATH" -mindepth 1 -type d -iname "*${QUERY}*" 2>/dev/null \
    | sort \
    | fzf --height=60% --reverse --no-info \
          --header="Matching folders — select destination  |  Esc = exit" \
          --preview '[ -d "{}" ] && ls -la --color=always -- "{}" || true' \
          --preview-window=right,50%) || quit

  [[ "$DEST" == "🚪"* ]] && quit

# ── 3B. FZF NAVIGATION ───────────────────────────────────────────────────────
else
  CUR="$BASE_PATH"
  STACK=()

  while true; do
    ITEMS=("✅  Select this folder:  $CUR" "📁  Create new folder here" "🚪  Exit")
    [ "${#STACK[@]}" -gt 0 ] && ITEMS+=("⬅️  Back")

    while IFS= read -r d; do
      ITEMS+=("$d")
    done < <(find "$CUR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

    CHOICE=$(printf '%s\n' "${ITEMS[@]}" \
      | fzf --height=70% --reverse --no-info \
            --header="📂 $CUR" \
            --preview '[ -d "{}" ] && ls -la --color=always -- "{}" || true' \
            --preview-window=right,50%) || quit

    case "$CHOICE" in
      "✅"*)
        DEST="$CUR"
        break
        ;;
      "📁"*)
        read -r -p "New folder name: " NEW_NAME
        [ -n "$NEW_NAME" ] || quit
        DEST="$CUR/$NEW_NAME"
        mkdir -p -- "$DEST"
        echo "✅ Created: $DEST"
        break
        ;;
      "🚪"*)
        quit
        ;;
      "⬅️"*)
        CUR="${STACK[-1]}"
        unset 'STACK[-1]'
        ;;
      *)
        STACK+=("$CUR")
        CUR="$CHOICE"
        ;;
    esac
  done
fi

[ -n "${DEST:-}" ] || quit
echo "🛬 Destination: $DEST"

# ── 4. SELECT SOURCE(S) ──────────────────────────────────────────────────────
echo "🔎 Select files or folders to send:"
mapfile -t SELECTED < <(
  find . -mindepth 1 -maxdepth 1 -printf '%T@ %P\0' \
  | sort -rz -k1,1 \
  | sed -z 's/^[^ ]* //' \
  | fzf_multiselect --read0 --height=80% --reverse \
        --prompt="$(pwd)/ > " \
        --preview 'p="{}"; if [ -d "$p" ]; then ls -la --color=always -- "$p"; else file -b -- "$p"; fi' \
        --preview-window=right,60%
)

[ "${#SELECTED[@]}" -gt 0 ] || quit

SRCS=()
for s in "${SELECTED[@]}"; do
  SRCS+=("${s%/}")
done

echo "📦 Sources:"
printf '   %s\n' "${SRCS[@]}"
echo "🛬 Destination: $DEST"

# ── 5. RSYNC ─────────────────────────────────────────────────────────────────
echo
do_rsync "$DEST" "${SRCS[@]}"

echo "✅ Done."
