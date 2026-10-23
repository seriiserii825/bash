#!/bin/bash
# WordPress helpers: open wp-config.php in nvim, add FluentSMTP credentials to wp-config.php,
# toggle WP_HTTP_BLOCK_EXTERNAL / debug mode in wp-config.php, toggle display:none in src/scss/partials/base.scss,
# open / watch / reset debug.log, copy it to ~/Downloads.
# wp-config.php ищется вверх по родительским директориям от $PWD.
# SMTP credentials come from the repo-root .env (gpg-encrypted at rest, see .gpgrc).

source /home/serii/dotfiles/zsh_modules/zsh_colors

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="$(cd "$script_dir/.." && pwd)/.env"

# печатает путь к ближайшему wp-config.php в родительских директориях
function findWpConfig() {
  local dir
  dir="$(pwd)"

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/wp-config.php" ]]; then
      echo "$dir/wp-config.php"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  echo "${tmagenta}⚠️ wp-config.php not found in any parent directory.${treset}" >&2
  return 1
}

function openWpConfig() {
  local wp_config
  wp_config=$(findWpConfig) || return 1
  nvim "$wp_config"
}

# Safe to re-run: errors out if the constants are already defined instead of duplicating them.
function setSmtp() {
  if [[ ! -f "$env_file" ]]; then
    echo "${tmagenta}⚠️ Missing ${env_file}. Decrypt .env.gpg first (see .gpgrc).${treset}"
    return 1
  fi

  source "$env_file"

  if [[ -z "${FLUENTMAIL_SMTP_USERNAME:-}" || -z "${FLUENTMAIL_SMTP_PASSWORD:-}" ]]; then
    echo "${tmagenta}⚠️ FLUENTMAIL_SMTP_USERNAME / FLUENTMAIL_SMTP_PASSWORD not set in ${env_file}.${treset}"
    return 1
  fi

  local wp_config
  wp_config=$(findWpConfig) || return 1
  echo "Found: ${wp_config}"

  if grep -q "FLUENTMAIL_SMTP_USERNAME" "$wp_config" || grep -q "FLUENTMAIL_SMTP_PASSWORD" "$wp_config"; then
    echo "${tmagenta}⚠️ FLUENTMAIL_SMTP_USERNAME/FLUENTMAIL_SMTP_PASSWORD already defined in ${wp_config}.${treset}"
    return 1
  fi

  {
    echo ""
    printf "define( 'FLUENTMAIL_SMTP_USERNAME', '%s' );\n" "$FLUENTMAIL_SMTP_USERNAME"
    printf "define( 'FLUENTMAIL_SMTP_PASSWORD', '%s' );\n" "$FLUENTMAIL_SMTP_PASSWORD"
  } >> "$wp_config"

  echo "${tgreen}🟢 Added FLUENTMAIL SMTP credentials to ${wp_config}${treset}"
}

function toggleHttpBlockExternal() {
  local wp_config target="WP_HTTP_BLOCK_EXTERNAL"
  wp_config=$(findWpConfig) || return 1

  local match
  match=$(grep -n "$target" "$wp_config" | head -n1)

  if [ -z "$match" ]; then
    echo "${tmagenta}⚠️ ${target} not found in ${wp_config}${treset}"

    local define_line="define( 'WP_HTTP_BLOCK_EXTERNAL', true );"

    read -rp "${tblue}Add it now? (y/N): ${treset}" add_answer

    if [[ "$add_answer" =~ ^[Yy]$ ]]; then
      local marker_line
      marker_line=$(grep -n "That's all, stop editing" "$wp_config" | head -n1 | cut -d: -f1)

      if [ -n "$marker_line" ]; then
        sed -i "${marker_line}i ${define_line}" "$wp_config"
      else
        printf '\n%s\n' "$define_line" >> "$wp_config"
      fi

      echo "${tgreen}🟢 Added: ${define_line}${treset}"
    else
      echo "Skipped"
    fi

    return 0
  fi

  local line_num line_content status
  line_num=$(echo "$match" | cut -d: -f1)
  line_content=$(echo "$match" | cut -d: -f2-)

  if echo "$line_content" | grep -Eq '^[[:space:]]*//'; then
    status="commented"
    echo "${tmagenta}🔵 ${target} is currently commented:${treset}"
  else
    status="active"
    echo "${tgreen}🟢 ${target} is currently active:${treset}"
  fi

  echo "${line_content}"

  read -rp "${tblue}Do you want to toggle it? (y/N): ${treset}" answer

  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [ "$status" == "commented" ]; then
      sed -i "${line_num}s#^\([[:space:]]*\)//[[:space:]]*#\1#" "$wp_config"
      echo "${tgreen}🟢 Uncommented ${target}${treset}"
    else
      sed -i "${line_num}s#^\([[:space:]]*\)#\1// #" "$wp_config"
      echo "${tmagenta}🔵 Commented ${target}${treset}"
    fi
  else
    echo "Skipped"
  fi
}

# комментирует (// ) строки a..b, уже закомментированные не трогает
function commentLines() {
  sed -i -E "${1},${2}{/^[[:space:]]*\/\//!s#^([[:space:]]*)#\1// #}" "$3"
}

function uncommentLines() {
  sed -i -E "${1},${2}s#^([[:space:]]*)// ?#\1#" "$3"
}

# Debug on:  комментирует дефолтный блок `if ( ! defined( 'WP_DEBUG' ) ) {...}` (или `define( 'WP_DEBUG', false )`)
#            и раскомментирует debug-строки, недостающие добавляет под дефолтным блоком.
# Debug off: комментирует debug-строки и раскомментирует дефолтный блок.
function toggleDebug() {
  local wp_config
  wp_config=$(findWpConfig) || return 1
  echo "Found: ${wp_config}"

  local q="['\"]" c="^[[:space:]]*(//[[:space:]]*)?"
  local debug_lines=(
    "define('WP_DEBUG', true);"
    "define('WP_DEBUG_LOG', true);"
    "define('WP_DEBUG_DISPLAY', false);"
    "@ini_set('display_errors', 0);"
  )
  local debug_res=(
    "${c}define[[:space:]]*\([[:space:]]*${q}WP_DEBUG${q}[[:space:]]*,[[:space:]]*true"
    "${c}define[[:space:]]*\([[:space:]]*${q}WP_DEBUG_LOG${q}"
    "${c}define[[:space:]]*\([[:space:]]*${q}WP_DEBUG_DISPLAY${q}"
    "${c}@?ini_set[[:space:]]*\([[:space:]]*${q}display_errors${q}"
  )

  # дефолтный блок: if ( ! defined( 'WP_DEBUG' ) ) { ... }, иначе одиночный define( 'WP_DEBUG', false )
  local def_start def_end
  def_start=$(grep -nE "${c}if[[:space:]]*\([[:space:]]*![[:space:]]*defined[[:space:]]*\([[:space:]]*${q}WP_DEBUG${q}" "$wp_config" | head -n1 | cut -d: -f1)
  if [ -n "$def_start" ]; then
    def_end=$(tail -n "+${def_start}" "$wp_config" | grep -nE "${c}\}" | head -n1 | cut -d: -f1)
    def_end=$((def_start + def_end - 1))
  else
    def_start=$(grep -nE "${c}define[[:space:]]*\([[:space:]]*${q}WP_DEBUG${q}[[:space:]]*,[[:space:]]*false" "$wp_config" | head -n1 | cut -d: -f1)
    def_end=$def_start
  fi

  if [ -n "$def_start" ]; then
    echo "${tblue}Default block (lines ${def_start}-${def_end}):${treset}"
    sed -n "${def_start},${def_end}p" "$wp_config"
  else
    echo "${tmagenta}⚠️ Default WP_DEBUG block not found.${treset}"
  fi

  local i n found_nums=()
  echo "${tblue}Debug lines:${treset}"
  for i in "${!debug_res[@]}"; do
    n=$(grep -nE "${debug_res[$i]}" "$wp_config" | head -n1 | cut -d: -f1)
    found_nums[i]=$n
    if [ -n "$n" ]; then
      echo "  ${n}: $(sed -n "${n}p" "$wp_config")"
    else
      echo "  ${tmagenta}missing:${treset} ${debug_lines[$i]}"
    fi
  done

  local active=0
  if [ -n "${found_nums[0]}" ] && ! sed -n "${found_nums[0]}p" "$wp_config" | grep -Eq '^[[:space:]]*//'; then
    active=1
  fi

  if [ $active -eq 1 ]; then
    echo "${tgreen}🟢 Debug mode is currently ON${treset}"
    read -rp "${tblue}Turn debug mode OFF? (y/N): ${treset}" answer
  else
    echo "${tmagenta}🔵 Debug mode is currently OFF${treset}"
    read -rp "${tblue}Turn debug mode ON? (y/N): ${treset}" answer
  fi

  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Skipped"
    return 0
  fi

  if [ $active -eq 1 ]; then
    for n in "${found_nums[@]}"; do
      [ -n "$n" ] && commentLines "$n" "$n" "$wp_config"
    done
    [ -n "$def_start" ] && uncommentLines "$def_start" "$def_end" "$wp_config"
    echo "${tmagenta}🔵 Debug mode OFF${treset}"
    return 0
  fi

  [ -n "$def_start" ] && commentLines "$def_start" "$def_end" "$wp_config"

  local missing=()
  for i in "${!debug_lines[@]}"; do
    if [ -n "${found_nums[$i]}" ]; then
      uncommentLines "${found_nums[$i]}" "${found_nums[$i]}" "$wp_config"
    else
      missing+=("${debug_lines[$i]}")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    local anchor=$def_end
    if [ -z "$anchor" ]; then
      anchor=$(grep -n "That's all, stop editing" "$wp_config" | head -n1 | cut -d: -f1)
      [ -n "$anchor" ] && anchor=$((anchor - 1))
    fi

    if [ -n "$anchor" ] && [ "$anchor" -gt 0 ]; then
      printf '%s\n' "${missing[@]}" | sed -i "${anchor}r /dev/stdin" "$wp_config"
    else
      printf '%s\n' "${missing[@]}" >> "$wp_config"
    fi
    echo "${tgreen}🟢 Added:${treset}"
    printf '  %s\n' "${missing[@]}"
  fi

  echo "${tgreen}🟢 Debug mode ON${treset}"
}

# запускать из папки темы (где лежит src/scss/partials/base.scss)
function toggleBodyAfter() {
  local file="src/scss/partials/base.scss"

  if [ ! -f "$file" ]; then
    echo "${tmagenta}⚠️ File ${file} not found.${treset}"
    return 1
  fi

  if grep -Eq '^[[:space:]]*/\* display: none; \*/[[:space:]]*$' "$file"; then
    # "/* display: none; */" → "display: none;"
    sed -i 's@^[[:space:]]*/\* display: none; \*/[[:space:]]*$@    display: none;@' "$file"
    echo "${tgreen}🟠 Uncommented: display: none;${treset}"
  elif grep -Eq '^[[:space:]]*display: none;[[:space:]]*$' "$file"; then
    # "display: none;" → "/* display: none; */"
    sed -i 's@^[[:space:]]*display: none;[[:space:]]*$@    /* display: none; */@' "$file"
    echo "${tgreen}🔵 Commented: display: none;${treset}"
  else
    echo "${tmagenta}⚠️ Target line not found.${treset}"
  fi
}

# печатает путь к wp-content/debug.log рядом с найденным wp-config.php
function findDebugLog() {
  local wp_config debug_log
  wp_config=$(findWpConfig) || return 1
  debug_log="$(dirname "$wp_config")/wp-content/debug.log"

  if [[ ! -f "$debug_log" ]]; then
    echo "${tmagenta}⚠️ ${debug_log} not found.${treset}" >&2
    return 1
  fi

  echo "$debug_log"
}

function openDebugLog() {
  local debug_log
  debug_log=$(findDebugLog) || return 1
  nvim "$debug_log"
}

function watchDebugLog() {
  local debug_log
  debug_log=$(findDebugLog) || return 1
  echo "Watching ${debug_log} with bat (Ctrl+C to stop)..."
  tail -F "$debug_log" | bat --paging=never -l log
}

function resetDebugLog() {
  local debug_log
  debug_log=$(findDebugLog) || return 1
  echo "Found: ${debug_log} ($(du -h "$debug_log" | cut -f1))"
  : > "$debug_log"
  echo "${tgreen}🟢 debug.log cleared${treset}"
}

# копирует в ~/Downloads/debug.log, если такой уже есть — добавляет дату к имени
function copyDebugLog() {
  local debug_log target="$HOME/Downloads/debug.log"
  debug_log=$(findDebugLog) || return 1
  mkdir -p "$HOME/Downloads"
  [[ -e "$target" ]] && target="$HOME/Downloads/debug-$(date +%Y-%m-%d_%H-%M-%S).log"
  cp "$debug_log" "$target"
  echo "${tgreen}🟢 Copied ${debug_log} -> ${target}${treset}"
}

echo "${tgreen}1) Open wp-config in neovim${treset}"
echo "${tblue}2) Set FluentSMTP in wp-config${treset}"
echo "${tmagenta}3) Toggle WP_HTTP_BLOCK_EXTERNAL${treset}"
echo "${tcyan}4) Toggle body after (display: none)${treset}"
echo "${tyellow}5) Toggle debug mode${treset}"
echo "${tgreen}6) Open debug.log in neovim${treset}"
echo "${tblue}7) Watch debug.log (bat live)${treset}"
echo "${tmagenta}8) Reset debug.log${treset}"
echo "${tcyan}9) Copy debug.log to Downloads${treset}"
echo "10) Exit"
read -rp "Select an option: " option

case $option in
  1)
    openWpConfig
    ;;
  2)
    setSmtp
    ;;
  3)
    toggleHttpBlockExternal
    ;;
  4)
    toggleBodyAfter
    ;;
  5)
    toggleDebug
    ;;
  6)
    openDebugLog
    ;;
  7)
    watchDebugLog
    ;;
  8)
    resetDebugLog
    ;;
  9)
    copyDebugLog
    ;;
  10)
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac
