source "$(dirname "$0")/encrypt.sh"

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

      set -x
      directory=$(basename "$clipboard" .git)
      set +x
      if [ -d "$directory" ]; then
        cd "$directory"
      else
        echo "Error: $directory not found"
        return 1
      fi

      decryptFiles

      return
    fi
  done

  echo "No recognized URL found in clipboard."
  return 1
}
