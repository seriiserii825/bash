function pull(){
  # check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    git pull
  else
    push
    git pull
  fi
}

function decryptFiles(){
  # check for .gpgrc file if exists
  if [ -f ".gpgrc" ]; then
    # read lines
    while IFS= read -r line; do
      # line its a filename end with gpg, get file name without gpg
      filename=$(echo "$line" | sed 's/\.gpg$//')
      echo "$filename"
      # check if file exists
      if [ -f "$line" ]; then
        # remove filename
        rm -f "$filename"
        # decrypt file
        gpg -d "$line" > "$filename"
      else
        echo "${tred}Error: $filename not found${treset}"
      fi
    done < ".gpgrc"
  else
    echo "${tmagenta}No .gpgrc file found. Exiting...${treset}"
  fi
}

function gitPull(){
  pull
  decryptFiles
}
