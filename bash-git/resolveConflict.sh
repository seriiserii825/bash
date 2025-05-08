function gitResolveConflict() {
  STRATEGY="$1"
  FILE_PATH="$2"

  if [ -z "$FILE_PATH" ] || [ -z "$STRATEGY" ]; then
    echo "Usage:   git-resolve-conflict <strategy> <file>"
    echo ""
    echo "Example: git-resolve-conflict --ours package.json"
    echo "Example: git-resolve-conflict --union package.json"
    echo "Example: git-resolve-conflict --theirs package.json"
    return
  fi

  git show :1:"$FILE_PATH" > ./tmp.common
  git show :2:"$FILE_PATH" > ./tmp.ours
  git show :3:"$FILE_PATH" > ./tmp.theirs

  git merge-file "$STRATEGY" -p ./tmp.ours ./tmp.common ./tmp.theirs > "$FILE_PATH"
  git add "$FILE_PATH"

  rm ./tmp.common
  rm ./tmp.ours
  rm ./tmp.theirs
}

function findFilesWithConflict() {
  git diff --name-only --diff-filter=U | while read -r file; do
  echo $file
done
}

function resolveConflict() {
  select action in Each_file All_files; do
    case $action in
      Each_file)
        git diff --name-only --diff-filter=U | while read -r file; do
        file_path=$(find . -name "$file" -type f)
        echo $file_path
        cat $file_path
        resolveOneFile $file
      done
      ;;
    All_files)
      resolveAllFiles
      break
      ;;
    *)
      echo "ERROR! Please select between 1..3"
      ;;
  esac
done
}

function resolveAllFiles(){
  defaultOption="ours" # Set the default option here
  # read -p "${tblue}Select an option: 
  # ours
  # theirs
  # by default is ours: ${treset}" choice

  print "Select an option, (ours/theirs), by default is ours: "
  read -r choice

  if [ -z "$choice" ]; then
    choice=$defaultOption
    echo "${tblue}Default option selected: $choice ${treset}"
  fi

  case $choice in
    ours)
      git diff --name-only --diff-filter=U | while read -r file; do
      gitResolveConflict --ours "$file"
    done
    ;;
  theirs)
    git diff --name-only --diff-filter=U | while read -r file; do
    gitResolveConflict --theirs "$file"
  done
  ;;
*)
  echo "${tred}${twhiteb}Invalid option selected${treset}"
  ;;
esac
}


function resolveEachFile(){
  git diff --name-only --diff-filter=U | while read -r file; do
  # file_path=$(find . -name "$file" -type f)
  bat $file
  select action in "--ours" "--theirs"; do
    case $action in
      "--ours") gitResolveConflict --ours "$file"
        break
        ;;
      "--theirs") gitResolveConflict --theirs "$file"
        break
        ;; 
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done </dev/tty
done
}

resolveConflict(){
  COLUMNS=1
  select action in "Find files with conflict" "Resolve all files" "Resolve each file" "Exit"; do
    case $action in
      "Find files with conflict" ) findFilesWithConflict;;
      "Resolve all files" ) 
        resolveAllFiles
        break
        ;;
      "Resolve each file" ) 
        resolveEachFile
        break
        ;;
      "Exit" )
        echo "Exiting..."
        break
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}
