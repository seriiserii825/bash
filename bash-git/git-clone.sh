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

      directory=$(basename "$clipboard" .git)
      if [ -d "$directory" ]; then
        echo "$directory" > /tmp/git_last_clone_dir
        cd "$(cat /tmp/git_last_clone_dir)"
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
