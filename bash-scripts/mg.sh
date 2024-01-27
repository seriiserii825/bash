#! /bin/bash



function changeImage(){
select size_direction in WIDTH HEIGHT FLOP
do
    case $size_direction in
        WIDTH)
          echo "${tblue}Enter the width: ${treset}"
            read  width
            mogrify -resize $width"x" $*
            break
            ;;
        HEIGHT)
          echo "${tyellow}Enter the width: ${treset}"
            read  height
            mogrify -resize x$height $*
            break
            ;;
        FLOP)
          mogrify -flop $*
            break
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
}

select which in "one" "all"
do
  case $which in 
    one)
      file_path=$( fzf )
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

