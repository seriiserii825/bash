#!/bin/bash
# Interactive Go package searcher: choose Global/Local, search pkg.go.dev,
# pick with fzf, copy install command to clipboard
# Global -> go install <packagePath>@latest
# Local  -> go get <packagePath>

set -euo pipefail

CLI_BIN="pkgsite-cli"
CLI_PKG="golang.org/x/pkgsite/cmd/internal/pkgsite-cli@latest"

copy_to_clipboard() {
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$1" | xclip -selection clipboard
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$1" | wl-copy
  else
    echo "Установите xclip или wl-copy для копирования в буфер" >&2
    return 1
  fi
}

if ! command -v "$CLI_BIN" >/dev/null 2>&1; then
  echo "📦 $CLI_BIN не найден, устанавливаю..."
  go install "$CLI_PKG"
  if ! command -v "$CLI_BIN" >/dev/null 2>&1; then
    echo "❌ Не удалось найти $CLI_BIN после установки. Проверьте \$GOPATH/bin в PATH." >&2
    exit 1
  fi
fi

mode=$(printf 'Global\nLocal' | fzf \
  --height=20% \
  --reverse \
  --header="📦 Тип установки")

if [ -z "$mode" ]; then
  echo "Ничего не выбрано"
  exit 0
fi

read -p "Название пакета: " query
if [ -z "$query" ]; then
  echo "Пустой запрос, выход"
  exit 1
fi

results=$("$CLI_BIN" search -json "$query" 2>/dev/null | jq -r '.items[] | "\(.packagePath)\t\(.modulePath)\t\(.version)\t\(.synopsis)"')

if [ -z "$results" ]; then
  echo "Ничего не найдено по запросу: $query"
  exit 0
fi

selected=$(echo "$results" | fzf \
  --delimiter='\t' \
  --with-nth=1,4 \
  --height=50% \
  --reverse \
  --header="📦 Go пакеты по запросу: $query")

if [ -z "$selected" ]; then
  echo "Ничего не выбрано"
  exit 0
fi

package_path=$(echo "$selected" | cut -f1)

if [ "$mode" = "Global" ]; then
  install_cmd="go install $package_path@latest"
else
  install_cmd="go get $package_path"
fi

if copy_to_clipboard "$install_cmd"; then
  echo "✓ Скопировано в буфер: $install_cmd"
else
  echo "Команда для установки: $install_cmd"
fi
