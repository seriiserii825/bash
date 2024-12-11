#! /bin/bash

function changeImage(){
  ls -la 
  echo -e "${tgreen}Select an option${treset}"
  echo "${tblue}1. Info${treset}"
  echo "${tyellow}2. Optimize${treset}"
  echo "${tgreen}3. Width${treset}"
  echo "${tblue}4. Height${treset}"
  echo "${tgreen}5. Flop${treset}"
  echo "${tgreen}5.1 Flop current and copy${treset}"
  echo "${tblue}6. Rotate${treset}"
  echo "${tmagenta}7. Exit${treset}"
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
    3)
      echo "${tblue}Enter the width: ${treset}"
      read  width
      mogrify -resize $width"x" $*
      changeImage $*
      ;;
    4)
      echo "${tyellow}Enter the height: ${treset}"
      read  height
      mogrify -resize x$height $*
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
      exit 0
      ;;
    *)
      echo "Invalid option"
      exit 0
      ;;
  esac
}

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

