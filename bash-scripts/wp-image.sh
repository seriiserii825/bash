#!/bin/bash

# выбрать картинку через fzf
image_path=$(find . -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | fzf --prompt="Select an image: ")
image_name=$(basename "$image_path")

findPostByImage(){
wp db query "SELECT ID, post_title, post_type 
FROM wp_posts 
WHERE post_content LIKE '%$1%'
   OR post_content LIKE '%\"id\":$1%';"

wp db query "
SELECT DISTINCT 
  REGEXP_REPLACE(pm.meta_key, '_[0-9]+.*', '') AS acf_group,
  pm.meta_key,
  p.post_title,
  pm.meta_value
FROM wp_postmeta pm
JOIN wp_posts p ON p.ID = pm.post_id
WHERE pm.meta_value LIKE '%$1%';
"
}

findImageIdByName(){
wp db query "
SELECT p.ID, p.post_title, pm.meta_value AS file
FROM wp_posts p
JOIN wp_postmeta pm ON pm.post_id = p.ID
WHERE p.post_type = 'attachment'
  AND pm.meta_key = '_wp_attached_file'
  AND pm.meta_value LIKE '%$1%';
"
}

findPostByImageId(){
  read -p "Enter the image ID: " image_id
wp db query "
SELECT pm.post_id, p.post_title, p.post_type, pm.meta_key
FROM wp_postmeta pm
JOIN wp_posts p ON p.ID = pm.post_id
WHERE pm.meta_value = '$image_id';
"
}

showImageAlt(){
wp db query "
SELECT p.ID, p.post_title, pm.meta_value AS alt
FROM wp_posts p
LEFT JOIN wp_postmeta pm 
  ON (p.ID = pm.post_id AND pm.meta_key = '_wp_attachment_image_alt')
WHERE p.post_type = 'attachment' 
  AND p.post_mime_type LIKE 'image/%'
ORDER BY p.ID DESC;
"
}

echo "Searching for posts containing a specific image ID or filename in WordPress database..."

while true; do
    select option in \
        "Find posts by image ID or filename" \
        "Find image ID by filename" \
        "Find posts by image ID" \
        "Show all image alts" \
        "Exit"; do
        case $option in
            "Find posts by image ID or filename")
                findPostByImage "$image_name"
                break
                ;;
            "Find image ID by filename")
                findImageIdByName "$image_name"
                break
                ;;
            "Find posts by image ID")
                findPostByImageId
                break
                ;;
              "Show all image alts")
                showImageAlt
                break
                ;;
            "Exit")
                echo "Bye 👋"
                exit 0
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
done
