#!/usr/bin/env bash

# Requirements:
# - wp-cli installed and configured
# - xclip or xsel available (to read clipboard)
# - Bash 4+

# --- Helper: get image name from clipboard ---
if command -v xclip &>/dev/null; then
  IMAGE_NAME=$(xclip -o -selection clipboard)
elif command -v xsel &>/dev/null; then
  IMAGE_NAME=$(xsel --clipboard)
else
  echo "No clipboard tool found (need xclip or xsel)"
  exit 1
fi

# Trim spaces
IMAGE_NAME=$(echo "$IMAGE_NAME" | xargs)

echo "📋 Image name from clipboard: '$IMAGE_NAME'"

# --- Functions ---

# Get siteurl once (helps building full URLs)
SITEURL=$(wp option get siteurl 2>/dev/null)

find_image_id() {
  echo "🔍 Finding image ID(s) by name: $IMAGE_NAME"
  # 1) Try by GUID
  wp db query "
    SELECT ID, post_title AS title, guid
    FROM wp_posts
    WHERE post_type='attachment' AND guid LIKE '%$IMAGE_NAME%';
  "
  echo
  # 2) Also try by meta _wp_attached_file (covers cases where GUID changed)
  wp db query "
    SELECT post_id AS ID, meta_value AS _wp_attached_file
    FROM wp_postmeta
    WHERE meta_key='_wp_attached_file' AND meta_value LIKE '%/$IMAGE_NAME';
  "
}

_usage_from_content_by_filename() {
  local FILENAME="$1"
  echo "📰 Posts whose content contains filename:"
  wp db query "
    SELECT ID, post_title, post_type
    FROM wp_posts
    WHERE post_status NOT IN ('trash','auto-draft','inherit')
      AND post_content LIKE '%$FILENAME%';
  "
}

_usage_from_content_by_url() {
  local URL="$1"
  echo "📰 Posts whose content contains full URL:"
  wp db query "
    SELECT ID, post_title, post_type
    FROM wp_posts
    WHERE post_status NOT IN ('trash','auto-draft','inherit')
      AND post_content LIKE '%$URL%';
  "
}

_usage_from_meta_by_id() {
  local ATTID="$1"
  echo "🧩 postmeta rows referencing attachment ID (exact or serialized):"
  wp db query "
    SELECT post_id, meta_key
    FROM wp_postmeta
    WHERE meta_value='$ATTID'
       OR meta_value LIKE '%:\"$ATTID\"%';
  "
}

find_post_parent_for_image() {
  echo "🔍 Finding parent post for image (and usage if unattached)…"

  # Prefer raw/TSV output (one row per line, columns = tab-separated)
  # 1) Try by GUID
  ATT_ROWS=$(wp db query --raw --skip-column-names "
    SELECT ID, post_parent, guid
    FROM wp_posts
    WHERE post_type = 'attachment'
      AND guid LIKE '%$IMAGE_NAME%';
  " 2>/dev/null)

  # 2) If nothing by GUID, try via _wp_attached_file (covers changed GUIDs)
  if [ -z "$ATT_ROWS" ]; then
    ATT_ROWS=$(wp db query --raw --skip-column-names "
      SELECT p.ID, p.post_parent, pm.meta_value
      FROM wp_posts p
      JOIN wp_postmeta pm
        ON pm.post_id = p.ID AND pm.meta_key = '_wp_attached_file'
      WHERE p.post_type = 'attachment'
        AND pm.meta_value LIKE '%/$IMAGE_NAME';
    " 2>/dev/null)
  fi

  if [ -z "$ATT_ROWS" ]; then
    echo "❌ No attachment found for '$IMAGE_NAME'. Run option 1 first to confirm."
    return
  fi

  echo -e "ID\tpost_parent\tguid_or_file"
  echo "$ATT_ROWS"

  # Build siteurl once for full URL checks
  SITEURL=$(wp option get siteurl 2>/dev/null)

  # Helpers
  _usage_from_content_by_filename() {
    local FILENAME="$1"
    wp db query --raw --skip-column-names "
      SELECT ID, post_title, post_type
      FROM wp_posts
      WHERE post_status NOT IN ('trash','auto-draft','inherit')
        AND post_content LIKE '%$FILENAME%';
    "
  }

  _usage_from_content_by_url() {
    local URL="$1"
    wp db query --raw --skip-column-names "
      SELECT ID, post_title, post_type
      FROM wp_posts
      WHERE post_status NOT IN ('trash','auto-draft','inherit')
        AND post_content LIKE '%$URL%';
    "
  }

  _usage_from_meta_by_id() {
    local ATTID="$1"
    wp db query --raw --skip-column-names "
      SELECT post_id, meta_key
      FROM wp_postmeta
      WHERE meta_value = '$ATTID'
         OR meta_value LIKE '%:\"$ATTID\"%';
    "
  }

  # For each found attachment row
  while IFS=$'\t' read -r ATTID PARENT COL3; do
    [ -z "$ATTID" ] && continue
    if [ "$PARENT" != "0" ]; then
      echo "✅ Attachment $ATTID is attached to post_parent=$PARENT"
      TITLE=$(wp post get "$PARENT" --field=post_title 2>/dev/null || true)
      [ -n "$TITLE" ] && echo "   Title: $TITLE"
    else
      echo "⚠️ Attachment $ATTID is unattached (post_parent=0). Searching usage…"

      echo "— by filename in post_content —"
      _usage_from_content_by_filename "$IMAGE_NAME" || true

      # Build a full URL if we got a file path instead of GUID
      if [[ "$COL3" == http* ]]; then
        ATT_URL="$COL3"
      else
        ATT_URL="$SITEURL/wp-content/uploads/$COL3"
      fi

      echo "— by full URL in post_content —"
      _usage_from_content_by_url "$ATT_URL" || true

      echo "— in postmeta by attachment ID —"
      _usage_from_meta_by_id "$ATTID" || true
    fi
  done <<< "$ATT_ROWS"
}

find_post_title() {
  read -rp "Enter Post ID: " PID
  echo "📄 Post title for ID $PID:"
  wp post get "$PID" --field=post_title
}

find_post_type() {
  read -rp "Enter part or full Post Title: " TITLE
  echo "📄 Searching post type for '$TITLE'..."
  wp db query "
    SELECT ID, post_title, post_type, post_status
    FROM wp_posts
    WHERE post_status NOT IN ('trash','auto-draft','inherit')
      AND post_title LIKE '%$TITLE%';
  "
}

# --- Menu loop ---
while true; do
  echo ""
  echo "========== IMAGE SEARCH MENU =========="
  echo "1) Find image ID (by name)"
  echo "2) Find post parent for image (and usage if unattached)"
  echo "3) Find post title by ID"
  echo "4) Find post type by title"
  echo "5) Exit"
  echo "======================================="
  read -rp "Choose an option [1-5]: " opt
  echo ""

  case "$opt" in
    1) find_image_id ;;
    2) find_post_parent_for_image ;;
    3) find_post_title ;;
    4) find_post_type ;;
    5) echo "👋 Bye!"; exit 0 ;;
    *) echo "Invalid option. Try again." ;;
  esac
done
