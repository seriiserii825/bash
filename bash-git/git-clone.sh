function gitClone() {
  clipboard=$(xclip -o)
  urls=("github.com" "bitbucket.org" "gitlab.com" "repo clone")

  for url in "${urls[@]}"; do
    if [[ "$clipboard" == *"$url"* ]]; then
      echo "Match found: $url"

      if [[ $url == "github.com" ]]; then
        git clone "$clipboard"
      else
        $clipboard
      fi

      directory=$(basename "$clipboard" .git)
      if [ -d "$directory" ]; then
        echo "Directory $directory exists."
        cd "$directory"
      else
        echo "Error: $directory not found"
        return 1
      fi

      return
    fi
  done

  echo "No recognized URL found in clipboard."
  return 1
}
