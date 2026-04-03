function getProjectType() {
  types=("nuxt" "next" "vue" "react" "wordpress")
  if [ -f "functions.php" ]; then
    echo "wordpress"
    return 0
  fi
  if [ -f "package.json" ]; then
    for type in "${types[@]}"; do
      if grep -q "\"$type\"" package.json; then
        echo "$type"
        return 0
      fi
    done
  else
    echo "${tmagenta}Missing package.json file. Please run this script in the root directory of your project.${treset}"
    exit 1
  fi
}
