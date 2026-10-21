#!/bin/bash
# Go repos manager: update go-libs across projects, dump repo urls to file, clone repos from file

source /home/serii/dotfiles/zsh_modules/zsh_colors

root=~/Documents/go
urls_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/go-repos-urls.txt"
mod=github.com/seriiserii825/go-libs

function updateRepos() {
  local summary=()
  local failed=()

  for gomod in "$root"/*/go.mod; do
    # только проекты, где go-libs в require (сам go-libs пропускается)
    grep -qE "^[[:space:]]*(require[[:space:]]+)?$mod[[:space:]]+v" "$gomod" || continue

    local dir name current latest now
    dir=$(dirname "$gomod")
    name=$(basename "$dir")
    echo "=== $name ==="
    cd "$dir" || continue

    read -r current latest < <(GOWORK=off GOPROXY=direct go list -m -u \
      -f '{{.Version}} {{if .Update}}{{.Update.Version}}{{end}}' "$mod")
    if [ $? -ne 0 ]; then
      failed+=("$name")
      summary+=("$name|-|ОШИБКА")
      cd - >/dev/null
      echo
      continue
    fi

    if [ -z "$latest" ]; then
      echo "уже последней версии ($current)"
      summary+=("$name|$current|без изменений")
    else
      echo "Обновляю $current -> $latest..."
      if GOWORK=off GOPROXY=direct go get "$mod@$latest" &&
        GOWORK=off go mod tidy &&
        GOWORK=off go install .; then
        now=$(GOWORK=off go list -m -f '{{.Version}}' "$mod")
        git add go.mod go.sum
        if git diff --cached --quiet; then
          summary+=("$name|$current -> $now|обновлён (без изменений в git)")
        elif git commit -m "go-libs was updated to $now" &&
          git push; then
          summary+=("$name|$current -> $now|обновлён, закоммичен и запушен")
        else
          failed+=("$name")
          summary+=("$name|$current -> $now|ОШИБКА commit/push")
        fi
      else
        failed+=("$name")
        summary+=("$name|-|ОШИБКА")
      fi
    fi

    cd - >/dev/null
    echo
  done

  echo "=== Итог ==="
  printf '%s\n' "${summary[@]}" | column -t -s '|'

  if [ ${#failed[@]} -gt 0 ]; then
    echo "${tred}Ошибки в: ${failed[*]}${treset}"
  fi
}

function reposToFile() {
  touch "$urls_file"

  for dir in "$root"/*/; do
    [ -d "$dir/.git" ] || continue
    local url
    url=$(git -C "$dir" remote get-url origin 2>/dev/null)
    [ -z "$url" ] && continue

    if grep -qxF "$url" "$urls_file"; then
      echo "Уже есть: $url"
    else
      echo "Добавляю: $url"
      echo "$url" >> "$urls_file"
    fi
  done
}

function cloneRepos() {
  if [ ! -f "$urls_file" ]; then
    echo "${tred}Файл $urls_file не найден${treset}"
    return 1
  fi

  while IFS= read -r url; do
    [ -z "$url" ] && continue

    local name
    name=$(basename "$url" .git)
    local dir="$root/$name"

    if [ -d "$dir" ]; then
      echo "Уже существует: $name"
      continue
    fi

    echo "Клонирую $url..."
    if git clone "$url" "$dir"; then
      (cd "$dir" && go install .)
    else
      echo "${tred}Не удалось клонировать $url${treset}"
    fi
  done < "$urls_file"
}

echo "${tgreen}1) Go update repos${treset}"
echo "${tblue}2) Go repos to file${treset}"
echo "${tmagenta}3) Clone go repos${treset}"
echo "4) Exit"
read -rp "Select an option: " option

case $option in
  1)
    updateRepos
    ;;
  2)
    reposToFile
    ;;
  3)
    cloneRepos
    ;;
  4)
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac
