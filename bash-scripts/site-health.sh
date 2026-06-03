#!/bin/bash

domain=$(xclip -selection clipboard -o | grep -oP '^https?://[^/]+')

if [[ ! "$domain" =~ ^https?:// ]]; then
    notify-send "site-health" "Not a valid URL: $domain" --urgency=critical
    echo "Error: not a valid URL: $domain"
    exit 1
fi

result="${domain}/wp-admin/site-health.php?tab=debug#health-check-section-wp-server"
echo -n "$result" | xclip -selection clipboard
notify-send "site-health" "$result"
echo "$result"
