#!/bin/bash

VENV_DIR="${1:-venv}"
shift

if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
  echo "❌ Virtualenv not found at '$VENV_DIR'"
  return 1
fi

# Save current shell options
set +u +e

# Source the venv, run mypy, then deactivate
(
  source "$VENV_DIR/bin/activate"

  if [[ $# -eq 0 ]]; then
    mypy .
  else
    mypy "$@"
  fi

  deactivate
)
