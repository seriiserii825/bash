#!/usr/bin/env bash
# Shows Chrome extension keyboard shortcuts from a profile's real Preferences file, searchable via fzf

set -euo pipefail

CHROME_DIR="${CHROME_DIR:-/home/serii/.config/google-chrome}"

check_deps() {
    if ! command -v jq &>/dev/null; then
        echo "Error: 'jq' is required but not installed." >&2; exit 1
    fi
    if ! command -v fzf &>/dev/null; then
        echo "Error: 'fzf' is required but not installed." >&2; exit 1
    fi
}

pick_profile() {
    local list=""
    for dir in "$CHROME_DIR"/*/; do
        local prefs="${dir}Preferences"
        [[ -f "$prefs" ]] || continue
        local folder name
        folder="$(basename "$dir")"
        name="$(jq -r '.profile.name // empty' "$prefs" 2>/dev/null)"
        list+="${name:-$folder} ($folder)"$'\n'
    done

    if [[ -z "$list" ]]; then
        echo "Error: no Chrome profiles found in $CHROME_DIR" >&2
        exit 1
    fi

    local chosen
    chosen=$( { printf '%s' "$list" | sed '/^$/d'; printf 'Exit\n'; } \
        | fzf --prompt="profile > " --height=11 --no-info \
              --header="esc/ctrl-c also exits" --bind="esc:abort,ctrl-c:abort" )
    [[ -z "$chosen" || "$chosen" == "Exit" ]] && exit 0

    echo "$chosen" | sed -n 's/.*(\(.*\))$/\1/p'
}

# resolves manifest.json path on disk: packed extensions store a path relative
# to <profile>/Extensions/, unpacked (dev mode) extensions store an absolute path
manifest_path_for() {
    local path="$1"
    [[ -z "$path" ]] && { echo ""; return; }
    if [[ "$path" == /* ]]; then
        echo "$path/manifest.json"
    else
        echo "$profile_dir/Extensions/$path/manifest.json"
    fi
}

# resolves a Chrome __MSG_key__ i18n placeholder via the extension's _locales/<default_locale>/messages.json
resolve_locale_message() {
    local manifest_json="$1" key="$2"
    local default_locale
    default_locale="$(jq -r '.default_locale // empty' "$manifest_json" 2>/dev/null)"
    [[ -z "$default_locale" ]] && { echo ""; return; }
    local locale_file="$(dirname "$manifest_json")/_locales/$default_locale/messages.json"
    [[ -f "$locale_file" ]] || { echo ""; return; }
    jq -r --arg k "$key" '.[$k].message // .[($k|ascii_downcase)].message // empty' "$locale_file" 2>/dev/null
}

# name from cached Preferences (mname) if present, else read manifest.json from disk,
# then resolve __MSG_...__ placeholders, else fall back to the raw extension id
resolve_name() {
    local mname="$1" path="$2" ext_id="$3"
    local manifest_json name
    manifest_json="$(manifest_path_for "$path")"

    name="$mname"
    if [[ -z "$name" && -n "$manifest_json" && -f "$manifest_json" ]]; then
        name="$(jq -r '.name // empty' "$manifest_json" 2>/dev/null)"
    fi

    if [[ "$name" == __MSG_*__ && -n "$manifest_json" && -f "$manifest_json" ]]; then
        local key msg
        key="${name#__MSG_}"; key="${key%__}"
        msg="$(resolve_locale_message "$manifest_json" "$key")"
        [[ -n "$msg" ]] && name="$msg"
    fi

    [[ -z "$name" ]] && name="$ext_id"
    echo "$name"
}

friendly_command() {
    case "$1" in
        _execute_action|_execute_browser_action) echo "Open popup" ;;
        _execute_page_action) echo "Open popup (page action)" ;;
        *) echo "$1" ;;
    esac
}

COMMAND_COL_WIDTH=20

truncate_str() {
    local s="$1" max="$2"
    if (( ${#s} > max )); then
        echo "${s:0:$((max - 1))}…"
    else
        echo "$s"
    fi
}

check_deps

profile="${1:-}"
if [[ -z "$profile" ]]; then
    profile="$(pick_profile)"
fi

prefs="$CHROME_DIR/$profile/Preferences"
if [[ ! -f "$prefs" ]]; then
    echo "Error: Preferences not found: $prefs" >&2
    exit 1
fi
profile_dir="$(dirname "$prefs")"

# fields are joined with \x1f (Unit Separator) rather than a real tab: bash's
# `read` treats tab as "IFS whitespace" and silently collapses empty fields,
# which would misalign columns whenever $mname (often empty) is blank
raw_rows="$(jq -r '
    .extensions.settings as $settings
    | .extensions.commands
    | to_entries[]
    | (.key | sub("^linux:"; "") | sub("^mac:"; "") | sub("^chromeos:"; "") | sub("^windows:"; "")) as $shortcut
    | .value.extension as $ext_id
    | .value.command_name as $command_name
    | ($settings[$ext_id]) as $info
    | (($info.manifest.name) // "") as $mname
    | (($info.path) // "") as $path
    | [$shortcut, $ext_id, $command_name, $mname, $path]
    | join("")
' "$prefs" 2>/dev/null)"

if [[ -z "$raw_rows" ]]; then
    echo "No extension shortcuts found for profile: $profile"
    exit 0
fi

rows=""
while IFS=$'\x1f' read -r shortcut ext_id command_name mname path; do
    name="$(resolve_name "$mname" "$path" "$ext_id")"
    cmd_label="$(truncate_str "$(friendly_command "$command_name")" "$COMMAND_COL_WIDTH")"
    rows+="$name"$'\t'"$cmd_label"$'\t'"$shortcut"$'\n'
done <<< "$raw_rows"

sorted_rows="$(printf '%s' "$rows" | sort -t $'\t' -k1,1)"

{ printf 'EXTENSION\tCOMMAND\tSHORTCUT\n'; printf '%s\n' "$sorted_rows"; } \
    | column -t -s $'\t' \
    | fzf --prompt="shortcut (esc to quit) > " --header-lines=1 --height=40% --no-info \
          --bind="esc:abort,ctrl-c:abort"
