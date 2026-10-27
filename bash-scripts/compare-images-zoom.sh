#!/bin/bash
# Compares zoomed 3x3 grid sections of 2 fzf-selected images (jpg/png) in nsxiv, crops are saved to test-<n>/ folder

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

scale=300

echo "Choose 2 images with fzf"
sleep 1

mapfile -t images < <(find . -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -not -path "./test-*" | sed 's|^\./||' | sort | fzf_multiselect)

if [[ ${#images[@]} -ne 2 ]]; then
    echo "Select exactly 2 images (selected: ${#images[@]})."
    exit 1
fi

image1="${images[0]}"
image2="${images[1]}"

# crops of both images have the same file name parts, so mark them by number and original extension
name1="$(basename "${image1%.*}")-${image1##*.}"
name2="$(basename "${image2%.*}")-${image2##*.}"

n=1
while [[ -e "test-$n" ]]; do
    n=$((n + 1))
done
dir="test-$n"
mkdir -p "$dir"

read -r width height < <(magick identify -format "%w %h\n" "$image1[0]")
read -r width2 height2 < <(magick identify -format "%w %h\n" "$image2[0]")
section_width=$((width / 3))
section_height=$((height / 3))

# second image with other dimensions is resized to the first, so the same area is compared
resize2=()
if [[ "${width2}x${height2}" != "${width}x$height" ]]; then
    resize2=(-resize "${width}x${height}!")
fi

fileSize() {
    du -h "$1" | cut -f1
}

# $1 - section name, $2 $3 - column and row
showSection() {
    local section=$1 col=$2 row=$3
    local geometry="${section_width}x${section_height}+$((col * section_width))+$((row * section_height))"
    local crop1="$dir/$section-1-$name1.png"
    local crop2="$dir/$section-2-$name2.png"

    magick "$image1[0]" -crop "$geometry" +repage -scale "${scale}%" "$crop1"
    magick "$image2[0]" "${resize2[@]}" -crop "$geometry" +repage -scale "${scale}%" "$crop2"

    nsxiv "$crop1" "$crop2"
}

while true; do
    clear
    echo "Image 1: $image1 ($(fileSize "$image1"), ${width}x${height})"
    echo "Image 2: $image2 ($(fileSize "$image2"), ${width2}x${height2})"
    echo "Crops:   $dir/"
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
    echo "  Enter - exit"
    echo
    echo "In nsxiv: n/p - flip images, q - close nsxiv and back to this menu"

    # Drop keys typed in the terminal while nsxiv was open
    while read -rsn1 -t 0.01; do :; done
    read -rsn1 key

    case "$key" in
        q) showSection top-left 0 0 ;;
        w) showSection top-center 1 0 ;;
        e) showSection top-right 2 0 ;;
        a) showSection middle-left 0 1 ;;
        s) showSection middle-center 1 1 ;;
        d) showSection middle-right 2 1 ;;
        z) showSection bottom-left 0 2 ;;
        x) showSection bottom-center 1 2 ;;
        c) showSection bottom-right 2 2 ;;
        f) nsxiv -z 100 "$image1" "$image2" ;;
        +) scale=$((scale + 100)) ;;
        -) ((scale > 100)) && scale=$((scale - 100)) ;;
        "") exit 0 ;;
    esac
done
