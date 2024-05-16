#! /bin/bash

# npm uninstall -g ttf2woff && Purge woff2

function checkFonts(){
  woff2_is_installed=$(which woff2_compress)
  ttf2woff_is_installed=$(npm ls -g | grep ttf2woff)
  if [ -z "$woff2_is_installed" ]; then
    echo "${tmagenta}woff2_compress is not installed${treset}"
    select yn in "Install woff2_compress" "Exit"; do
      case $yn in
        "Install woff2_compress" ) 
          sudo apt install woff2 -y; 
          break
          ;;
        "Exit" ) exit;;
      esac
    done
  fi
  if [ -z "$ttf2woff_is_installed" ]; then
    echo "${tmagenta}ttf2woff is not installed${treset}"
    select yn in "Install ttf2woff" "Exit"; do
      case $yn in
        "Install ttf2woff" ) 
          echo "use node > 16"
          npm install -g ttf2woff; 
          break
          ;;
        "Exit" ) exit;;
      esac
    done
  fi
}

function ttfToWoff2() {
  if ls *.ttf 1> /dev/null 2>&1; then
    for file in *.ttf; do
      woff2_compress "$file"
      ttf2woff "$file" "${file%.*}.woff" 
    done
    rm *.ttf
  else
    echo "${tmagenta}no ttf files found${treset}"
  fi
}

function woffToCss(){
  woff_files=$(find . -maxdepth 1 -type f -name "*.woff")
  woff2_files=$(find . -maxdepth 1 -type f -name "*.woff2")

  if [[ -n "$woff2_files" && -n "$woff_files" ]]; then
    touch fonts.css
    read -p "Enter relative path to fonts folder (default: assets/fonts): " rel_path
    if [[ -n "$rel_path" ]]; then
      rel_path="${rel_path%/}"
    else
      rel_path='assets/fonts'
    fi
    for file in *.woff; do
      # Extract font name from the file name by removing the extension and any style information
      font_original="${file%.*}"
      font_name=$(echo "$font_original" | tr '[:upper:]' '[:lower:]')

      font_style="normal"
      font_weight="normal"

      if [[ $font_name == *"italic"* ]]; then
        font_style="italic"
      fi

      if [[ $font_name == *"thin"* ]]; then
        font_weight="100"
      elif [[ $font_name == *"extralight"* ]]; then
        font_weight="200"
      elif [[ $font_name == *"light"* ]]; then
        font_weight="300"
      elif [[ $font_name == *"medium"* ]]; then
        font_weight="500"
      elif [[ $font_name == *"semibold"* || $font_name == *"demibold"* ]]; then
        font_weight="600"
      elif [[ $font_name == *"bold"* ]]; then
        font_weight="700"
      elif [[ $font_name == *"extrabold"* ]]; then
        font_weight="800"
      elif [[ $font_name == *"black"* || $font_name == *"heavy"* ]]; then
        font_weight="900"
      else
        font_weight="400"
      fi
      # echo "font_weight: $font_weight"
      font_name="${font_name%%-*}"  # Remove any style info
      capital_name="${font_name^}"

      echo "@font-face {
      font-family: '$capital_name'; 
      src: url('${rel_path}/${file%.*}.woff2') format('woff2'),
      url('${rel_path}/${file%.*}.woff') format('woff');
      font-weight: $font_weight;
      font-style: $font_style;
      font-display: swap;
    }" >> fonts.css
  done
  cat fonts.css | xclip -selection clipboard
  bat fonts.css
  rm fonts.css
else
  echo "${tmagenta}No .woff2 and woff files found.${treset}"
  fi
}

select action in info convert
do
  case $action in
    info)
      echo "${tgreen}Add to current directory ttf or woff and woff2 files${treset}"
      echo "${tgreen}This script will convert them to woff2 and woff and generate css file${treset}"
      echo "${tgreen}Css file will be copied to clipboard${treset}"
      ;;
    convert)
      checkFonts
      ttfToWoff2
      woffToCss
      break
      ;;
    *)
      echo "${tmagenta}invalid option${treset}"
      ;;
  esac
done


