closeScritpt(){
    echo "${tblue}Press Ctrl+C to restart or after 10 seconds terminal will close${treset}"
    sleep 10
    exit 1
}

checkNode(){
  # set -x
  file="package.json"

  # check if package.json exists
  if [ ! -e "$file" ]; then
    echo "${tmagenta}No $file${treset}"
    closeScritpt
  fi

  # find in package.json line with "node"
  node_line=$(grep "\"node\"" "$file")

  if [ -z "$node_line" ]; then
    echo "${tmagenta}No node line in $file${treset}"
    closeScritpt
  fi

  # extract version (remove quotes and spaces)
  node_version=$(echo "$node_line" | cut -d':' -f2 | tr -d '[:space:]' | tr -d '"')

  if [ -z "$node_version" ]; then
    echo "${tmagenta}No node version in $file${treset}"
    closeScritpt
  fi

  # if version starts with ^
  if [[ $node_version == ^* ]]; then
    echo "Node version has ^"
    node_version=${node_version#^}
  fi

  echo "Node version: $node_version"

  # check current node version
  current_version=$(node -v | tr -d 'v')

  # check if current version is equal to node version
  if [[ $current_version == $node_version ]]; then
    echo "Node version: $current_version"
  else
    export NVM_DIR="$HOME/.config/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Check if node version is already installed
    if ! nvm ls "$node_version" | grep -q "$node_version"; then
      echo "Node version $node_version not found. Installing..."
      nvm install "$node_version" || {
        echo "Failed to install Node version $node_version"
              return
            }
    fi

    # check if yarn is installed
    if ! command -v yarn &> /dev/null; then
        echo "Failed to install Yarn" return
    fi

    # Use the version
    nvm use "$node_version" || {
      echo "Failed to switch to Node version $node_version"
          return
        }
  fi
  # set +x

  # check if bun is installed
  if ! command -v bun &> /dev/null; then
    echo "${tmagenta}Bun is not installed. I will install for you))).${treset}"
    npm i bun -g
  fi
}

yd(){
  checkNode
  yarn dev
}
yyd(){
  checkNode
  yarn && yarn dev
}

yb(){
  checkNode
  yarn build
}
yyb(){
  checkNode
  yarn && yarn build
}

bi(){
  checkNode
  bun install
}
bid(){
  checkNode
  bun install && bun run dev
}
bd(){
  checkNode
  bun run dev
}
bib(){
  checkNode
  bun install && bun run build
}
bb(){
  checkNode
  bun run build
}
ba(){
  checkNode
  bun add "$@"
}
