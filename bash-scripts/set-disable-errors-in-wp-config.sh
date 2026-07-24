#!/usr/bin/env bash
# Silences non-fatal PHP warnings/notices/deprecations that wp-cli prints via
# its own error handler (display_errors / WP_DEBUG_DISPLAY don't affect it,
# e.g. buggy plugins spamming "PHP Warning: ... on line N" on every command).
# Finds wp-config.php by searching parent directories from $PWD and inserts a
# WP_CLI-guarded set_error_handler() block before wp-settings.php is
# required. Fatal errors (E_ERROR/E_PARSE) are never handled by a user
# handler, so real failures still surface normally. Safe to re-run: skips if
# the block is already present.

set -e

tblue=$(tput setaf 4)
tgreen=$(tput setaf 2)
tmagenta=$(tput setaf 5)
treset=$(tput sgr0)

MARKER="set-disable-errors-in-wp-config.sh"

DIR="$(pwd)"
WP_CONFIG=""

while [[ "$DIR" != "/" ]]; do
  if [[ -f "$DIR/wp-config.php" ]]; then
    WP_CONFIG="$DIR/wp-config.php"
    break
  fi
  DIR="$(dirname "$DIR")"
done

if [[ -z "$WP_CONFIG" ]]; then
  echo "${tmagenta}⚠️ wp-config.php not found in any parent directory.${treset}"
  exit 1
fi

echo "Found: ${WP_CONFIG}"

if grep -q "$MARKER" "$WP_CONFIG"; then
  echo "${tgreen}🟢 Warning-suppression block already present, nothing to do.${treset}"
  exit 0
fi

REQUIRE_LINE=$(grep -n "wp-settings.php" "$WP_CONFIG" | head -n1 | cut -d: -f1)

if [[ -z "$REQUIRE_LINE" ]]; then
  echo "${tmagenta}⚠️ Could not find the wp-settings.php require line in ${WP_CONFIG}${treset}"
  exit 1
fi

read -rp "${tblue}Add wp-cli warning suppression block? (y/N): ${treset}" answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  echo "Skipped"
  exit 0
fi

TMP=$(mktemp)

head -n "$((REQUIRE_LINE - 1))" "$WP_CONFIG" > "$TMP"

cat >>"$TMP" <<PHP

/**
 * Added by ${MARKER}
 * WP-CLI prints PHP warnings/notices/deprecations via its own error handler,
 * which ignores display_errors/WP_DEBUG_DISPLAY. Silence just those
 * non-fatal levels for wp-cli so buggy plugins don't spam the terminal;
 * real errors (E_ERROR/E_PARSE) are never handled by a user handler and
 * still surface normally.
 */
if (defined('WP_CLI') && WP_CLI) {
  set_error_handler(static function (int \$errno): bool {
    return (bool) (\$errno & (E_WARNING | E_NOTICE | E_DEPRECATED | E_STRICT | E_USER_WARNING | E_USER_NOTICE | E_USER_DEPRECATED));
  });
}
PHP

tail -n "+${REQUIRE_LINE}" "$WP_CONFIG" >> "$TMP"

mv "$TMP" "$WP_CONFIG"

echo "${tgreen}🟢 Added wp-cli warning suppression block to ${WP_CONFIG}${treset}"
