fzf_multiselect() {
  fzf --multi \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-r:toggle-all' \
    --bind 'tab:toggle+down' \
    --bind 'esc:deselect-all' \
    --header 'ctrl-a: all  ctrl-r: reverse  esc: none  tab: toggle' \
    "$@" || true
}
