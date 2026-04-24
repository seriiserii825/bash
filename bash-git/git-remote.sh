function gitRemote() {
  clipboard=$(xclip -o)
  hosts=("github.com" "bitbucket.org" "gitlab.com")

  detected_host=""
  for host in "${hosts[@]}"; do
    if [[ "$clipboard" == *"$host"* ]]; then
      detected_host="$host"
      break
    fi
  done

  if [[ -z "$detected_host" ]]; then
    echo "${tred}Error: Clipboard does not contain a recognized git URL (github.com, bitbucket.org, gitlab.com)${treset}"
    return 1
  fi

  echo "${tgreen}Detected host: $detected_host${treset}"
  echo "${tgreen}URL: $clipboard${treset}"

  existing_remote=$(git remote get-url origin 2>/dev/null)

  if [[ -n "$existing_remote" ]]; then
    echo "Current origin: $existing_remote"
    print -n "Origin already exists. Set (update) it? (y/n): "
    read answer
    if [[ "$answer" != "y" ]]; then
      echo "Aborted."
      return 0
    fi
    git remote set-url origin "$clipboard"
    echo "${tgreen}Origin updated to: $clipboard${treset}"
  else
    print -n "No origin found. Add it? (y/n): "
    read answer
    if [[ "$answer" != "y" ]]; then
      echo "Aborted."
      return 0
    fi
    git remote add origin "$clipboard"
    echo "${tgreen}Origin added: $clipboard${treset}"
  fi

  git remote -v
}
