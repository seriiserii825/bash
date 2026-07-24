---
name: fzf-multiselect
description: Use whenever a bash script in this repo needs multi-select via fzf ("multi-select", "выбрать несколько", picking several files/items at once). Always use fzf_multiselect from bash-scripts/libs/fzf-multiselect.sh instead of fzf -m/--multi directly, per the rule in CLAUDE.md.
---

# fzf-multiselect

Правило из `CLAUDE.md`: для любого множественного выбора через fzf — всегда
`fzf_multiselect` из `bash-scripts/libs/fzf-multiselect.sh`, никогда `fzf -m`
или `fzf --multi` напрямую.

## Функция

```bash
# bash-scripts/libs/fzf-multiselect.sh
fzf_multiselect() {
  fzf --multi \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-r:toggle-all' \
    --bind 'tab:toggle+down' \
    --bind 'esc:deselect-all' \
    --header 'ctrl-a: all  ctrl-r: reverse  esc: none  tab: toggle' \
    "$@" || true
}
```

Важно: `esc` тут переопределён на "снять все галочки", а не на отмену/выход
fzf. Поэтому "выйти без выбора" = Enter с пустым выделением (или Ctrl-C).
Не полагаться на Esc как способ закрыть fzf в скриптах, использующих эту
функцию.

## Подключение

```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"
```

Если скрипт лежит не прямо в `bash-scripts/`, а во вложенной папке — путь к
`libs/fzf-multiselect.sh` подправить соответственно.

## Использование

```bash
files=$(find . -maxdepth 1 -name "*.gpg" -type f | fzf_multiselect)
```

Любые доп. аргументы (`--prompt=`, `--height=`, `--preview=`, `--read0` и
т.п.) пробрасываются в `fzf` как есть — функция их просто форвардит через
`"$@"`.

Результат — список выбранных строк, разделённых `\n` (или `\0` при
`--read0`), в stdout. Ничего не выбрано / Esc / Ctrl-C → пустой вывод, **не**
ошибка (`|| true` внутри функции гасит ненулевой код выхода fzf), так что
после вызова проверять пустоту явно:

```bash
selected=$(printf '%s\n' "${items[@]}" | fzf_multiselect --prompt="Pick: ")
[ -n "$selected" ] || { echo "Nothing selected"; exit 0; }
```

## Примеры вызовов в репозитории

- `docker.sh`: `selected=$(docker ps -a --format '{{.Names}}' | fzf_multiselect --prompt="Stop containers: ")`
- `gpg.sh`: `files=$(find . -maxdepth 1 -name "*.gpg" -type f | fzf_multiselect)`
- `redis-cli.sh`: `selected=$(printf '%s\n' "$KEYS_CACHE" | fzf_multiselect --prompt="Select keys to delete > " --height=50% --no-sort)`
- `rsync.sh`: `mapfile -t SELECTED < <(find ... -print0 | ... | fzf_multiselect --read0 --height=80% --reverse --prompt="$SRC_BASE/ > " --preview '...' --preview-window=right,60%)`
- `parse-json.sh`: цикл `while true; do selected=$(printf '%s\n' "$ALL_PATHS" | fzf_multiselect ...); [ -n "$selected" ] || break; ...; done` — множественный выбор с возвратом к списку после каждого раунда (скрипт не завершается на выборе, выход — Enter без выделения).

## Когда НЕ использовать

Для одиночного выбора (`fzf` без `--multi`) — обычный `fzf`, не
`fzf_multiselect`. Правило касается только множественного выбора.
