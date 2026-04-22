#! /bin/bash

function removeSpaces(){
  perl-rename 's/ /-/g' *
  perl-rename 's/----/-/g' *
  perl-rename 's/---/-/g' *
  perl-rename 's/--/-/g' *
}

function showSizes(){
  if [ $# -gt 0 ]; then
    find "$@" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
      -exec identify -format "%f | %wx%h\n" {} \; | sort | column -t -s'|'
    return
  fi
  find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
    -exec identify -format "%f | %wx%h\n" {} \; | sort | column -t -s'|'
  }

function showImageSize(){
  identify -format "%f | %wx%h\n" "$1"
}

function showBySize(){
  read -p "Show files larger than (e.g., 500k, 2M): " size_limit
  find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -size +$size_limit -exec du -h {} + | sort -rh

  read -p "Find by width? (y/n): " find_width_choice
  if [[ "$find_width_choice" == "y" ]]; then
    read -p "Enter minimum width (in px): " find_width
    find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
      -exec sh -c '
    w=$(identify -format "%w" "$1")
    if [ "$w" -gt '"$find_width"' ]; then
      h=$(identify -format "%h" "$1")
      echo "$1 | ${w}x${h}"
  fi
  ' _ {} \; | sort | column -t -s'|'
  fi

  read -p "Do you want to see dimensions of these files? (y/n): " show_dims
  if [[ "$show_dims" == "y" ]]; then
    find . -maxdepth 1 -type f -size +$size_limit \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
      -exec identify -format "%f | %wx%h\n" {} \; | sort | column -t -s'|'
  fi

  read -p "Do you want to resize images wider than 1920px? (y/n): " resize_choice
  if [[ "$resize_choice" == "y" ]]; then
    min_width=1920

    find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 |
      while IFS= read -r -d '' img; do
        w=$(identify -format "%w" "$img" 2>/dev/null) || continue
        if [[ "$w" -gt "$min_width" ]]; then
          mogrify -resize "${min_width}x>" "$img" && echo "Resized: $img (${w}px → ${min_width}px)"
        fi
      done

      echo "Resizing completed."
  fi
}

function filterImages(){
  local result=()
  for f in "$@"; do
    [[ "${f,,}" =~ \.(jpg|jpeg|png|webp)$ ]] && result+=("$f")
  done
  echo "${result[@]}"
}

function cropImage() {
  local imgs
  read -ra imgs <<< "$(filterImages "$@")"
  set -- "${imgs[@]}"
  read -p "Pixels to crop top,right,bottom,left (comma separated, leave empty for 0): " crop_values
  top_crop=$(echo $crop_values | cut -d',' -f1)
  right_crop=$(echo $crop_values | cut -d',' -f2)
  bottom_crop=$(echo $crop_values | cut -d',' -f3)
  left_crop=$(echo $crop_values | cut -d',' -f4)

  # Default empty inputs to zero
  top_crop=${top_crop:-0}
  bottom_crop=${bottom_crop:-0}
  left_crop=${left_crop:-0}
  right_crop=${right_crop:-0}

  echo "Cropping values - Top: $top_crop, Right: $right_crop, Bottom: $bottom_crop, Left: $left_crop"


  read -p "Are you sure you want to crop these images? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Crop operation cancelled."
    continue
  fi

  for img in "$@"; do
    if [[ ! -f "$img" ]]; then
      echo "File not found: $img"
      continue
    fi

    width=$(identify -format "%w" "$img")
    height=$(identify -format "%h" "$img")
    echo "Processing $img (original size: ${width}x$(identify -format "%h" "$img"))"

    # Calculate new width and height
    new_width=$((width - left_crop - right_crop))
    new_height=$((height - top_crop - bottom_crop))
    echo "New dimensions will be: ${new_width}x${new_height}"

    if (( new_width <= 0 || new_height <= 0 )); then
      echo "Error: Crop exceeds image dimensions for $img"
      continue
    fi


    base="${img%.*}"
    ext="${img##*.}"
    new_name="${base}-${top_crop}-${right_crop}-${bottom_crop}-${left_crop}.${ext}"
    cp "$img" "$new_name"
    mogrify -crop "${new_width}x${new_height}+${left_crop}+${top_crop}" +repage "$new_name"
    echo "Created: $new_name"

  done
  echo "Cropping completed."
}

function changeImage(){
  local imgs
  read -ra imgs <<< "$(filterImages "$@")"
  set -- "${imgs[@]}"
  echo -e "${tgreen}Select an option${treset}"
  echo "${tblue}1. Info${treset}"
  echo "${tyellow}2. Optimize${treset}"
  echo "${tyellow}2.1 Png to jpg${treset}"
  echo "${tgreen}3. Width${treset}"
  echo "${tblue}4. Height${treset}"
  echo "${tgreen}5. Flop${treset}"
  echo "${tgreen}5.1 Flop current and copy${treset}"
  echo "${tblue}6. Rotate${treset}"
  echo "${tblue}7. Crop${treset}"
  echo "${tmagenta}8. Exit${treset}"
  read -p "${tgreen}Enter your choice: ${treset}" choice
  case $choice in
    1)
      showSizes $*
      changeImage $*
      ;;
    2)
      for i in ls $*; do
        # check if i has ext jpg
        if [[ $i == *.jpg ]]; then
          jpegoptim --strip-all --all-progressive -ptm 80 $i
        elif [[ $i == *.png ]]; then
          pngquant $i --quality 80-90 --speed 1
        fi
      done
      # jpegoptim --strip-all --all-progressive -ptm 80 $*
      changeImage $*
      ;;
    2.1)
      mogrify -format jpg $* && rm $*
      ;;
    3)
      local before_sizes
      before_sizes=$(showSizes $*)
      echo "${tblue}Before:${treset}"
      echo "$before_sizes"
      echo "${tblue}Enter the width: ${treset}"
      read  width
      mogrify -resize $width"x" $*
      echo "${tgreen}After:${treset}"
      showSizes $*
      changeImage $*
      ;;
    4)
      local before_sizes
      before_sizes=$(showSizes $*)
      echo "${tblue}Before:${treset}"
      echo "$before_sizes"
      echo "${tyellow}Enter the height: ${treset}"
      read  height
      mogrify -auto-orient -resize x$height $*
      echo "${tgreen}After:${treset}"
      showSizes $*
      changeImage $*
      ;;
    5)
      mogrify -flop $*
      changeImage $*
      ;;
    5.1)
      current_file=$*
      new_file=$(echo $current_file | sed 's/\(.*\)\.\(.*\)/\1-flop.\2/')
      cp $current_file $new_file
      mogrify -flop $new_file
      changeImage $*
      ;;
    6)
      echo "${tblue}Enter the angle: ${treset}"
      read  angle
      mogrify -rotate $angle $*
      changeImage $*
      ;;
    7)
      echo "${tblue}Crop the image${treset}"
      cropImage $*
      changeImage $*
      ;;
    8)
      exit 0
      ;;
    *)
      echo "Invalid option"
      exit 0
      ;;
  esac
}

removeSpaces
COLUMNS=1
select which in "one" "all" "info" "size" "exit";
do
  case $which in 
    one)
      file_path=$( fzf )
      echo "${tgreen}Select image: $file_path${treset}"
      changeImage $file_path
      break
      ;;
    all)
      echo "${tgreen}Select all images${treset}"
      changeImage *
      break
      ;;
    info)
      showSizes
      break
      ;;
    size)
      echo "${tblue}Filter images by size${treset}"
      showBySize
      ;;
    exit)
      echo "Exiting..."
      break
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done

