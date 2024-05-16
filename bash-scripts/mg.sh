#! /bin/bash

function changeImage(){
COLUMNS=1
select size_direction in INFO OPTIMIZE WIDTH HEIGHT FLOP EXIT
do
    case $size_direction in
        INFO)
          echo -e "${tblue}Resolution of the image${treset}"
          identify -format "%wx%h\n" $*

          echo -e "${tgreen}Size of the image${treset}"
          du -sh $*
            ;;
        OPTIMIZE)
          jpegoptim --strip-all --all-progressive -ptm 80 $*
            ;;
        WIDTH)
          echo "${tblue}Enter the width: ${treset}"
            read  width
            mogrify -resize $width"x" $*
            ;;
        HEIGHT)
          echo "${tyellow}Enter the width: ${treset}"
            read  height
            mogrify -resize x$height $*
            ;;
        FLOP)
          mogrify -flop $*
            ;;
        EXIT)
          exit 0
            ;;
        *)
            echo "Invalid option"
            break
            ;;
    esac
done
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

