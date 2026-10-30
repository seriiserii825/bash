#!/bin/bash
# Go repos manager: update go-libs across projects, dump repo urls to file, clone repos from file, go install all projects

source /home/serii/dotfiles/zsh_modules/zsh_colors

root=~/Documents/go
urls_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/go-repos-urls.txt"
mod=github.com/seriiserii825/go-libs

# обновляет один проект; вывод идёт в лог, строка итога — в $tmp/$name.sum, ошибка — в $tmp/$name.fail
function updateRepo() {
  local dir=$1 latest=$2 tmp=$3
  local name current now
  name=$(basename "$dir")
  cd "$dir" || return

  {
    if ! current=$(GOWORK=off go list -m -f '{{.Version}}' "$mod"); then
      echo "$name|-|ОШИБКА" > "$tmp/$name.sum"
      touch "$tmp/$name.fail"
      return
    fi

    if [ "$current" = "$latest" ]; then
      echo "уже последней версии ($current)"
      echo "$name|$current|без изменений" > "$tmp/$name.sum"
      return
    fi

    echo "Обновляю $current -> $latest..."
    if GOWORK=off GOPROXY=direct go get "$mod@$latest" &&
      GOWORK=off go mod tidy &&
      GOWORK=off go install .; then
      now=$(GOWORK=off go list -m -f '{{.Version}}' "$mod")
      git add go.mod go.sum
      if git diff --cached --quiet; then
        echo "$name|$current -> $now|обновлён (без изменений в git)" > "$tmp/$name.sum"
      elif git commit -m "go-libs was updated to $now" &&
        git push; then
        echo "$name|$current -> $now|обновлён, закоммичен и запушен" > "$tmp/$name.sum"
      else
        echo "$name|$current -> $now|ОШИБКА commit/push" > "$tmp/$name.sum"
        touch "$tmp/$name.fail"
      fi
    else
      echo "$name|-|ОШИБКА" > "$tmp/$name.sum"
      touch "$tmp/$name.fail"
    fi
  } > "$tmp/$name.log" 2>&1
}

function updateRepos() {
  local latest tmp dirs=() failed=()

  # последнюю версию go-libs узнаём один раз, а не в каждом проекте
  echo "Получаю последнюю версию $mod..."
  if ! latest=$(cd /tmp && GOWORK=off GOPROXY=direct go list -m -f '{{.Version}}' "$mod@latest"); then
    echo "${tred}Не удалось получить последнюю версию $mod${treset}"
    return 1
  fi
  echo "Последняя версия: $latest"
  echo

  tmp=$(mktemp -d)

  for gomod in "$root"/*/go.mod; do
    # только проекты, где go-libs в require (сам go-libs пропускается)
    grep -qE "^[[:space:]]*(require[[:space:]]+)?$mod[[:space:]]+v" "$gomod" || continue
    local dir
    dir=$(dirname "$gomod")
    dirs+=("$dir")
    (updateRepo "$dir" "$latest" "$tmp") &
  done
  wait

  local name
  for dir in "${dirs[@]}"; do
    name=$(basename "$dir")
    echo "=== $name ==="
    cat "$tmp/$name.log"
    echo
    [ -f "$tmp/$name.fail" ] && failed+=("$name")
  done

  echo "=== Итог ==="
  for dir in "${dirs[@]}"; do
    cat "$tmp/$(basename "$dir").sum"
  done | column -t -s '|'

  if [ ${#failed[@]} -gt 0 ]; then
    echo "${tred}Ошибки в: ${failed[*]}${treset}"
  fi

  rm -rf "$tmp"
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

function installRepos() {
  local failed=()

  for gomod in "$root"/*/go.mod; do
    local dir name
    dir=$(dirname "$gomod")
    name=$(basename "$dir")
    # только CLI-проекты: package main в корне модуля (библиотеки вроде go-libs пропускаются)
    [ "$(cd "$dir" && GOWORK=off go list -f '{{.Name}}' . 2>/dev/null)" = "main" ] || continue

    echo "=== $name ==="
    if (cd "$dir" && GOWORK=off go install .); then
      echo "${tgreen}установлен${treset}"
    else
      failed+=("$name")
    fi
  done

  if [ ${#failed[@]} -gt 0 ]; then
    echo "${tred}Ошибки в: ${failed[*]}${treset}"
  fi
}

echo "${tgreen}1) Go update repos${treset}"
echo "${tblue}2) Go repos to file${treset}"
echo "${tmagenta}3) Clone go repos${treset}"
echo "${tyellow}4) Go install all repos${treset}"
echo "5) Exit"
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
    installRepos
    ;;
  5)
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac
