#!/bin/bash
# Обходит все проекты в ~/Documents/go, которые зависят от go-libs,
# и если есть новая версия go-libs — обновляет go.mod и ставит бинарник (go install).
# В конце печатает сводку версий go-libs по всем проектам.

mod=github.com/seriiserii825/go-libs
root=~/Documents/go

summary=()
failed=()

update_project() {
  local name=$1 current latest now

  # текущая версия и доступное обновление (пусто, если обновления нет)
  read -r current latest < <(GOWORK=off GOPROXY=direct go list -m -u \
    -f '{{.Version}} {{if .Update}}{{.Update.Version}}{{end}}' "$mod") || return 1

  if [ -z "$latest" ]; then
    echo "уже последней версии ($current)"
    summary+=("$name|$current|без изменений")
    return 0
  fi

  echo "Обновляю $current -> $latest..."
  GOWORK=off GOPROXY=direct go get "$mod@$latest" &&
    GOWORK=off go mod tidy &&
    GOWORK=off go install . || return 1

  # проверяем, какая версия реально записалась в go.mod
  now=$(GOWORK=off go list -m -f '{{.Version}}' "$mod")
  summary+=("$name|$current -> $now|обновлён")
}

for gomod in "$root"/*/go.mod; do
  # только проекты, где go-libs в require (сам go-libs пропускается)
  grep -qE "^[[:space:]]*(require[[:space:]]+)?$mod[[:space:]]+v" "$gomod" || continue

  dir=$(dirname "$gomod")
  name=$(basename "$dir")
  echo "=== $name ==="
  # без subshell, иначе summary из функции потеряется
  cd "$dir" || continue
  if ! update_project "$name"; then
    failed+=("$name")
    summary+=("$name|-|ОШИБКА")
  fi
  cd - >/dev/null
  echo
done

echo "=== Итог ==="
printf '%s\n' "${summary[@]}" | column -t -s '|'

if [ ${#failed[@]} -gt 0 ]; then
  exit 1
fi
