function vueHandler() {
  if [ -f "package.json" ]; then
    if grep -q "\"vue\"" package.json; then
      echo "Vue.js project detected."
      npm install
      npm run build
    else
      echo "No Vue.js dependency found in package.json."
    fi
  else
    echo "No package.json file found. Please ensure you're in the correct directory."
  fi
}
