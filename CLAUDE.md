# Правила проекта

## fzf multi-select
Для любого множественного выбора через fzf всегда использовать функцию
`fzf_multiselect` из `bash-scripts/libs/fzf-multiselect.sh`, а не `fzf -m`/`fzf --multi` напрямую.

Подключение:
```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"
```

Использование:
```bash
files=$(find . -maxdepth 1 -name "*.gpg" -type f | fzf_multiselect)
```
