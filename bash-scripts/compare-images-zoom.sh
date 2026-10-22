#!/bin/bash
# Optimizes a fzf-selected JPEG with jpegoptim into <quality>/ folders and compares zoomed 3x3 grid sections with the original in sxiv

scale=300

echo "Choose an image with fzf"
sleep 1

original=$(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | sed 's|^\./||' | sort | fzf)

if [[ -z "$original" ]]; then
    echo "No image selected."
    exit 1
fi

name="${original%.*}"

read -r width height < <(magick identify -format "%w %h" "$original")
section_width=$((width / 3))
section_height=$((height / 3))

fileSize() {
    du -h "$1" | cut -f1
}

# $1 - quality folder, $2 - section name, $3 $4 - column and row
showSection() {
    local dir=$1 section=$2 col=$3 row=$4
    local geometry="${section_width}x${section_height}+$((col * section_width))+$((row * section_height))"
    local crop_original="$dir/$name-$section-1-original.png"
    local crop_optimized="$dir/$name-$section-2-q$dir.png"

    magick "$original" -crop "$geometry" +repage -scale "${scale}%" "$crop_original"
    magick "$dir/$original" -crop "$geometry" +repage -scale "${scale}%" "$crop_optimized"

    sxiv "$crop_original" "$crop_optimized"
}

sectionMenu() {
    local dir=$1

    while true; do
        clear
        echo "Original:  $original ($(fileSize "$original"))"
        echo "Optimized: $dir/$original ($(fileSize "$dir/$original"))"
        echo
        echo "Choose section (zoom ${scale}%):"
        echo
        echo "  q | w | e"
        echo "  --+---+--"
        echo "  a | s | d"
        echo "  --+---+--"
        echo "  z | x | c"
        echo
        echo "  f - full images at 100%"
        echo "  + / - change zoom"
        echo "  b - back to quality"
        echo
        echo "In sxiv: n/p - flip images, q - close sxiv and back to this menu"

        # Drop keys typed in the terminal while sxiv was open
        while read -rsn1 -t 0.01; do :; done
        read -rsn1 key

        case "$key" in
            q) showSection "$dir" top-left 0 0 ;;
            w) showSection "$dir" top-center 1 0 ;;
            e) showSection "$dir" top-right 2 0 ;;
            a) showSection "$dir" middle-left 0 1 ;;
            s) showSection "$dir" middle-center 1 1 ;;
            d) showSection "$dir" middle-right 2 1 ;;
            z) showSection "$dir" bottom-left 0 2 ;;
            x) showSection "$dir" bottom-center 1 2 ;;
            c) showSection "$dir" bottom-right 2 2 ;;
            f) sxiv -z 100 "$original" "$dir/$original" ;;
            +) scale=$((scale + 100)) ;;
            -) ((scale > 100)) && scale=$((scale - 100)) ;;
            b) return ;;
        esac
    done
}

while true; do
    clear
    echo "Original: $original ($(fileSize "$original"))"
    echo

    for dir in */; do
        dir=${dir%/}
        if [[ "$dir" =~ ^[0-9]+$ && -f "$dir/$original" ]]; then
            echo "  $dir: $(fileSize "$dir/$original")"
        fi
    done

    echo
    read -rp "Quality 1-100 (Enter - exit): " quality

    [[ -z "$quality" ]] && exit 0

    if [[ ! "$quality" =~ ^[0-9]+$ ]] || ((quality < 1 || quality > 100)); then
        continue
    fi

    mkdir -p "$quality"
    # --force: write the file even if jpegoptim finds no gain, so the folder always has a version to compare
    jpegoptim --strip-all --all-progressive --force --overwrite -m "$quality" -d "$quality" "$original" >/dev/null

    sectionMenu "$quality"
done
