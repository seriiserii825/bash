#! /bin/bash

function removeSpaces(){
  perl-rename 's/ /-/g' *
  perl-rename 's/----/-/g' *
  perl-rename 's/---/-/g' *
  perl-rename 's/--/-/g' *
}

function cropImage() {
  read -p "Pixels to crop from top (leave empty for 0): " top_crop
  read -p "Pixels to crop from bottom (leave empty for 0): " bottom_crop
  read -p "Pixels to crop from left (leave empty for 0): " left_crop
  read -p "Pixels to crop from right (leave empty for 0): " right_crop

  # Default empty inputs to zero
  top_crop=${top_crop:-0}
  bottom_crop=${bottom_crop:-0}
  left_crop=${left_crop:-0}
  right_crop=${right_crop:-0}

  for img in "$@"; do
    if [[ ! -f "$img" ]]; then
      echo "File not found: $img"
      continue
    fi

    width=$(identify -format "%w" "$img")
    height=$(identify -format "%h" "$img")

    # Calculate new width and height
    new_width=$((width - left_crop - right_crop))
    new_height=$((height - top_crop - bottom_crop))

    if (( new_width <= 0 || new_height <= 0 )); then
      echo "Error: Crop exceeds image dimensions for $img"
      continue
    fi

    # Crop geometry: WIDTHxHEIGHT+X+Y
    mogrify -crop "${new_width}x${new_height}+${left_crop}+${top_crop}" +repage "$img"
    echo "Cropped $img: top $top_crop, bottom $bottom_crop, left $left_crop, right $right_crop pixels"
  done
}

function changeImage(){
  ls -la 
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
      echo -e "${tblue}Resolution of the image${treset}"
      identify -format "%wx%h\n" $*
      echo -e "${tgreen}Size of the image${treset}"
      du -sh $*
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
      mogrify -format jpg *.png && rm *.png
      ;;
    3)
      echo "${tblue}Enter the width: ${treset}"
      read  width
      mogrify -resize $width"x" $*
      changeImage $*
      ;;
    4)
      echo "${tyellow}Enter the height: ${treset}"
      read  height
      mogrify -auto-orient -resize x$height $*
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
select which in "one" "all"
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
    *)
      echo "Invalid option"
      ;;
  esac
done

