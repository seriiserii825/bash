#!/usr/bin/env bash
# Adds FluentSMTP username/password define() lines to wp-config.php.
# Finds wp-config.php by searching parent directories from $PWD. Credentials
# come from set-smtp-to-wp-config-env.sh (gpg-encrypted at rest, see .gpgrc).
# Safe to re-run: errors out if the constants are already defined instead of
# duplicating them.

set -e

tblue=$(tput setaf 4)
tgreen=$(tput setaf 2)
tmagenta=$(tput setaf 5)
treset=$(tput sgr0)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/set-smtp-to-wp-config-env.sh"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "${tmagenta}⚠️ Missing ${ENV_FILE}. Decrypt set-smtp-to-wp-config-env.sh.gpg first (see .gpgrc).${treset}"
  exit 1
fi

source "$ENV_FILE"

if [[ -z "${FLUENTMAIL_SMTP_USERNAME:-}" || -z "${FLUENTMAIL_SMTP_PASSWORD:-}" ]]; then
  echo "${tmagenta}⚠️ FLUENTMAIL_SMTP_USERNAME / FLUENTMAIL_SMTP_PASSWORD not set in ${ENV_FILE}.${treset}"
  exit 1
fi

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

if grep -q "FLUENTMAIL_SMTP_USERNAME" "$WP_CONFIG" || grep -q "FLUENTMAIL_SMTP_PASSWORD" "$WP_CONFIG"; then
  echo "${tmagenta}⚠️ FLUENTMAIL_SMTP_USERNAME/FLUENTMAIL_SMTP_PASSWORD already defined in ${WP_CONFIG}.${treset}"
  exit 1
fi

{
  echo ""
  printf "define( 'FLUENTMAIL_SMTP_USERNAME', '%s' );\n" "$FLUENTMAIL_SMTP_USERNAME"
  printf "define( 'FLUENTMAIL_SMTP_PASSWORD', '%s' );\n" "$FLUENTMAIL_SMTP_PASSWORD"
} >> "$WP_CONFIG"

echo "${tgreen}🟢 Added FLUENTMAIL SMTP credentials to ${WP_CONFIG}${treset}"
