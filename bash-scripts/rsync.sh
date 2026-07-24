#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need fzf
need rsync

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/libs/fzf-multiselect.sh"

ENV_FILE="$(cd "$SCRIPT_DIR/.." && pwd)/.env"
[ -f "$ENV_FILE" ] && { set -a; source "$ENV_FILE"; set +a; }

quit() { echo "Exit."; exit 0; }

# Numbers each incoming line as "N) text" for menu display.
number_lines() { awk '{printf "%d) %s\n", NR, $0}'; }

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

# Syncs the contents of $1 into $2 (creates $2 if missing).
# Prompts for --delete (mirror mode: removes at destination what's gone at source).
do_folder_sync() {
  local src="$1" dest="$2"
  [ -d "$src" ] || { echo "❌ Folder '$src' not found."; exit 1; }
  mkdir -p -- "$dest"

  echo
  echo "[yellow]--delete: removes files at destination that no longer exist at source"
  echo "Without --delete: destination keeps files even if removed at source"
  read -r -p "Use --delete? (y/n, default n): " USE_DELETE
  local delete_flag=()
  [ "$USE_DELETE" = "y" ] && delete_flag=(--delete)

  echo "📦 Source:      $src/"
  echo "🛬 Destination: $dest/"
  read -r -p "Proceed? (y/n): " CONFIRM
  [ "$CONFIRM" = "y" ] || quit

  echo "▶️  rsync -av --progress ${delete_flag[*]:-} -- \"$src/\" \"$dest/\""
  rsync -av --progress "${delete_flag[@]}" -- "$src/" "$dest/"
  echo "✅ Done."
}

GARDALIVE_LOCAL="/home/serii/Local Sites/lc-gardalive/app/public/uploads"
GARDALIVE_MNT="/mnt/Projects/G/gardalive/uploads"
GARDALIVE_MNT_ROOT="/mnt/Projects/G/gardalive"

# Lets you pick a .wpress backup from $GARDALIVE_MNT_ROOT via fzf (newest first)
# and copies it into ~/Downloads.
do_wpress_to_downloads() {
  local dir="$GARDALIVE_MNT_ROOT"
  [ -d "$dir" ] || { echo "❌ Folder '$dir' not found."; exit 1; }

  local dest="$HOME/Downloads"
  mkdir -p -- "$dest"

  local picked
  picked=$(
    find "$dir" -maxdepth 1 -type f -name "*.wpress" -printf '%T@ %p\0' \
    | sort -rz -k1,1 \
    | sed -z 's/^[^ ]* //' \
    | tr '\0' '\n' \
    | number_lines \
    | fzf --height=60% --reverse --no-info \
          --header="Select .wpress backup (newest first) — Esc = exit" \
          --preview 'p="{}"; p="${p#*) }"; ls -la --color=always -- "$p"' \
          --preview-window=right,50%
  ) || quit
  picked="${picked#*) }"

  [ -n "$picked" ] || quit

  echo "📦 Source:      $picked"
  echo "🛬 Destination: $dest/"
  do_rsync "$dest" "$picked"
}

# Syncs between a local folder and a path on the gardalive VPS over rsync+ssh.
# $1 = "to" (local -> vps) or "from" (vps -> local)
do_vps_sync() {
  local direction="$1"
  need sshpass

  : "${GARDALIVE_VPS_HOST:?Missing GARDALIVE_VPS_HOST in .env}"
  : "${GARDALIVE_VPS_PORT:?Missing GARDALIVE_VPS_PORT in .env}"
  : "${GARDALIVE_VPS_USER:?Missing GARDALIVE_VPS_USER in .env}"
  : "${GARDALIVE_VPS_PASSWORD:?Missing GARDALIVE_VPS_PASSWORD in .env}"
  : "${GARDALIVE_VPS_UPLOADS_PATH:?Missing GARDALIVE_VPS_UPLOADS_PATH in .env}"

  local remote="${GARDALIVE_VPS_USER}@${GARDALIVE_VPS_HOST}:${GARDALIVE_VPS_UPLOADS_PATH}/"
  local local_="$GARDALIVE_LOCAL/"
  mkdir -p -- "$GARDALIVE_LOCAL"

  local src dest
  if [ "$direction" = "to" ]; then
    src="$local_"; dest="$remote"
  else
    src="$remote"; dest="$local_"
  fi

  echo
  echo "[yellow]--delete: removes files at destination that no longer exist at source"
  echo "Without --delete: destination keeps files even if removed at source"
  read -r -p "Use --delete? (y/n, default n): " USE_DELETE
  local delete_flag=()
  [ "$USE_DELETE" = "y" ] && delete_flag=(--delete)

  echo "📦 Source:      $src"
  echo "🛬 Destination: $dest"
  read -r -p "Proceed? (y/n): " CONFIRM
  [ "$CONFIRM" = "y" ] || quit

  echo "▶️  rsync -av --progress ${delete_flag[*]:-} -- \"$src\" \"$dest\""
  sshpass -p "$GARDALIVE_VPS_PASSWORD" rsync -av --progress \
    -e "sshpass -p $GARDALIVE_VPS_PASSWORD ssh -p $GARDALIVE_VPS_PORT" \
    "${delete_flag[@]}" -- "$src" "$dest"
  echo "✅ Done."
}

# ── 0. DIRECTION ─────────────────────────────────────────────────────────────
MODE=$(printf 'To folder (choose destination)\nFrom Downloads here\ngardalive uploads to mnt\ngardalive uploads from mnt\ngardalive uploads to vps\ngardalive uploads from vps\ngardalive from mnt to Downloads last wpress backup\n🚪 Exit' \
  | number_lines \
  | fzf --height=40% --reverse --no-info \
        --header="Select transfer direction") || quit
MODE="${MODE#*) }"

[[ "$MODE" == "🚪"* ]] && quit

# ── 0C. GARDALIVE UPLOADS ⇄ MNT ──────────────────────────────────────────────
if [ "$MODE" = "gardalive uploads to mnt" ]; then
  do_folder_sync "$GARDALIVE_LOCAL" "$GARDALIVE_MNT"
  exit 0
fi

if [ "$MODE" = "gardalive uploads from mnt" ]; then
  do_folder_sync "$GARDALIVE_MNT" "$GARDALIVE_LOCAL"
  exit 0
fi

# ── 0D. GARDALIVE UPLOADS ⇄ VPS ──────────────────────────────────────────────
if [ "$MODE" = "gardalive uploads to vps" ]; then
  do_vps_sync "to"
  exit 0
fi

if [ "$MODE" = "gardalive uploads from vps" ]; then
  do_vps_sync "from"
  exit 0
fi

if [ "$MODE" = "gardalive from mnt to Downloads last wpress backup" ]; then
  do_wpress_to_downloads
  exit 0
fi

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
  | number_lines \
  | fzf --height=40% --reverse --no-info \
        --header="Select starting folder") || quit
BASE_CHOICE="${BASE_CHOICE#*) }"

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
    | number_lines \
    | fzf --height=40% --reverse --no-info \
          --header="Select destination folder method  |  base: $BASE_PATH") || quit
  METHOD="${METHOD#*) }"

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
    | number_lines \
    | fzf --height=60% --reverse --no-info \
          --header="Matching folders — select destination  |  Esc = exit" \
          --preview 'p="{}"; p="${p#*) }"; [ -d "$p" ] && ls -la --color=always -- "$p" || true' \
          --preview-window=right,50%) || quit
  DEST="${DEST#*) }"

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
      | number_lines \
      | fzf --height=70% --reverse --no-info \
            --header="📂 $CUR" \
            --preview 'p="{}"; p="${p#*) }"; [ -d "$p" ] && ls -la --color=always -- "$p" || true' \
            --preview-window=right,50%) || quit
    CHOICE="${CHOICE#*) }"

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
