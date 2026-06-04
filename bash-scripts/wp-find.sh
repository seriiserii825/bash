#!/usr/bin/env bash
# WordPress universal finder via WP-CLI: find by slug, title, or ID across posts, taxonomies, menus

# Requirements:
# - wp-cli installed and configured
# - Bash 4+

# --- Helpers ---

_section() { echo -e "\n--- $1 ---"; }

find_by_slug() {
  read -rp "Enter slug: " SLUG
  SLUG=$(echo "$SLUG" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  _section "Posts / Pages / CPT (exact slug)"
  wp db query "
    SELECT ID, post_type, post_status, post_title
    FROM wp_posts
    WHERE post_name = '$SLUG'
      AND post_status NOT IN ('auto-draft','inherit');
  "

  _section "Posts / Pages / CPT (partial slug)"
  wp db query "
    SELECT ID, post_type, post_status, post_title
    FROM wp_posts
    WHERE post_name LIKE '%$SLUG%'
      AND post_status NOT IN ('auto-draft','inherit');
  "

  _section "Taxonomy terms (exact slug)"
  wp db query "
    SELECT t.term_id, tt.taxonomy, t.slug, t.name
    FROM wp_terms t
    JOIN wp_term_taxonomy tt ON t.term_id = tt.term_id
    WHERE t.slug = '$SLUG';
  "

  _section "Taxonomy terms (partial slug)"
  wp db query "
    SELECT t.term_id, tt.taxonomy, t.slug, t.name
    FROM wp_terms t
    JOIN wp_term_taxonomy tt ON t.term_id = tt.term_id
    WHERE t.slug LIKE '%$SLUG%';
  "

  _section "Nav menus (items with this slug)"
  wp db query "
    SELECT p.ID, p.post_title AS menu_item_title,
           pm_url.meta_value AS url,
           pm_slug.meta_value AS object_slug
    FROM wp_posts p
    JOIN wp_postmeta pm_slug ON pm_slug.post_id = p.ID
      AND pm_slug.meta_key = '_menu_item_url'
    LEFT JOIN wp_postmeta pm_url ON pm_url.post_id = p.ID
      AND pm_url.meta_key = '_menu_item_url'
    WHERE p.post_type = 'nav_menu_item'
      AND pm_slug.meta_value LIKE '%$SLUG%';
  "

  # Also check nav_menu_item by linked object slug
  wp db query "
    SELECT p.ID, p.post_title,
           pm_type.meta_value AS object_type,
           pm_id.meta_value   AS object_id
    FROM wp_posts p
    JOIN wp_postmeta pm_type ON pm_type.post_id = p.ID AND pm_type.meta_key = '_menu_item_type'
    JOIN wp_postmeta pm_id   ON pm_id.post_id   = p.ID AND pm_id.meta_key   = '_menu_item_object_id'
    WHERE p.post_type = 'nav_menu_item'
      AND pm_id.meta_value IN (
        SELECT ID FROM wp_posts WHERE post_name LIKE '%$SLUG%'
        UNION
        SELECT term_id FROM wp_terms WHERE slug LIKE '%$SLUG%'
      );
  "
}

find_by_title() {
  read -rp "Enter title (partial OK): " TITLE
  TITLE=$(echo "$TITLE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  _section "Posts / Pages / CPT"
  wp db query "
    SELECT ID, post_type, post_status, post_title, post_name AS slug
    FROM wp_posts
    WHERE post_title LIKE '%$TITLE%'
      AND post_status NOT IN ('auto-draft','inherit');
  "

  _section "Taxonomy terms"
  wp db query "
    SELECT t.term_id, tt.taxonomy, t.name, t.slug
    FROM wp_terms t
    JOIN wp_term_taxonomy tt ON t.term_id = tt.term_id
    WHERE t.name LIKE '%$TITLE%';
  "

  _section "Nav menu items"
  wp db query "
    SELECT ID, post_title, post_status
    FROM wp_posts
    WHERE post_type = 'nav_menu_item'
      AND post_title LIKE '%$TITLE%';
  "
}

find_by_id() {
  read -rp "Enter ID: " SID

  _section "Post / Page / CPT"
  wp db query "
    SELECT ID, post_type, post_status, post_title, post_name AS slug
    FROM wp_posts
    WHERE ID = $SID;
  "

  _section "Taxonomy term"
  wp db query "
    SELECT t.term_id, tt.taxonomy, t.name, t.slug, tt.count
    FROM wp_terms t
    JOIN wp_term_taxonomy tt ON t.term_id = tt.term_id
    WHERE t.term_id = $SID;
  "

  _section "Nav menu item"
  wp db query "
    SELECT p.ID, p.post_title,
           pm_type.meta_value AS item_type,
           pm_obj.meta_value  AS object_id,
           pm_url.meta_value  AS url
    FROM wp_posts p
    LEFT JOIN wp_postmeta pm_type ON pm_type.post_id = p.ID AND pm_type.meta_key = '_menu_item_type'
    LEFT JOIN wp_postmeta pm_obj  ON pm_obj.post_id  = p.ID AND pm_obj.meta_key  = '_menu_item_object_id'
    LEFT JOIN wp_postmeta pm_url  ON pm_url.post_id  = p.ID AND pm_url.meta_key  = '_menu_item_url'
    WHERE p.post_type = 'nav_menu_item'
      AND p.ID = $SID;
  "

  _section "Postmeta for this ID (first 20 rows)"
  wp db query "
    SELECT meta_key, meta_value
    FROM wp_postmeta
    WHERE post_id = $SID
    LIMIT 20;
  "
}

# --- Menu loop ---
while true; do
  echo ""
  echo "========== WP FIND =========="
  echo "1) Find by slug"
  echo "2) Find by title"
  echo "3) Find by ID"
  echo "4) Exit"
  echo "============================="
  read -rp "Choose an option [1-4]: " opt
  echo ""

  case "$opt" in
    1) find_by_slug ;;
    2) find_by_title ;;
    3) find_by_id ;;
    4) echo "Bye!"; exit 0 ;;
    *) echo "Invalid option." ;;
  esac
done
