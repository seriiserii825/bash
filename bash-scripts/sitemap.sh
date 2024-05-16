#!/bin/bash
url=$(xclip -o)

if ! [[ $url =~ ^https?://  ]]; then
  echo "${tmagenta}No URL found in clipboard${reset}"
  exit 1
fi
# URL of the XML file
xml_url="$url"

# Use curl to fetch the XML data and grep to extract the desired information
# xml_data=$(curl -s "$xml_url" | grep "<tag>")
xml_data=$(curl -s "$url/page-sitemap.xml" | grep "<loc>")

# Print the extracted XML data
echo "$xml_data"
function getMeta(){
  html_content=$1
  # Extract the meta title using grep
  meta_title=$(echo "$html_content" | grep -o -P '(?<=<title>).*?(?=</title>)')
  # Extract the meta description using grep
  meta_description=$(echo "$html_content" | grep -o -E '<meta\s+name="description"\s+content="([^"]+)"' | sed -E 's/<meta\s+name="description"\s+content="([^"]+)"/\1/' | head -n 1)

  echo "Meta: ==================="
  if [ -z "$meta_title" ]; then
    echo "${tmagenta}No meta title found${treset}"
  else
    echo "${tgreen}Meta Title:${treset} $meta_title"
  fi
  if [ -z "$meta_description" ]; then
    echo "${tmagenta}No meta description found${treset}"
  else
    echo "${tgreen}Meta Description:${treset} $meta_description"
  fi
}

function getTitles(){
  html_content=$1
  # Extract h1 tags
  h1_tags=$(echo "$html_content" | grep -o '<h1[^>]*>.*</h1>' | sed 's/<[^>]*>//g')

  # Extract h2 tags
  h2_tags=$(echo "$html_content" | grep -o '<h2[^>]*>.*</h2>' | sed 's/<[^>]*>//g')

  # Extract h3 tags
  h3_tags=$(echo "$html_content" | grep -o '<h3[^>]*>.*</h3>' | sed 's/<[^>]*>//g')

  # Output the results
  echo "${tyellow}h1 tags: ===================${treset}"
  echo "- $h1_tags"
  echo "${tblue}h2 tags: ===================${treset}"
  echo "-- $h2_tags"
  echo "${tgreen}h3 tags: ===================${treset}"
  echo "--- $h3_tags"
}

function getMetaTags() {
  type=$2
  html_content=$(curl -s "$1")
  # Output the meta title
  echo "===================================================================================================="
  echo "${tblue}URL: $1${treset}"
  echo "===================================================================================================="

  if [ "$type" == "titles" ]; then
    getTitles "$html_content"
  elif [ "$type" == "meta" ]; then
    getMeta "$html_content"
  else
    getMeta "$html_content"
    getTitles "$html_content"
  fi

  echo "-------------------"
}

function showPages() {
  for url in $xml_data; do
    text=$(echo "$url" | grep -oP '<loc>\K[^<]*')
    pathname=$(echo $text | grep -Po '\w\K/\w+[^?]+')
    echo $pathname
  done
}

function selectOne() {
  urls=()
  for url in $xml_data; do
    # Extract text from <loc> tags
    text=$(echo "$url" | grep -oP '<loc>\K[^<]*')
    urls+=("$text")
  done
  select url in "${urls[@]}"; do
    getMetaTags "$url"
    break
  done
}

COLUMNS=1
select option in  "Show Pages"  "Show Meta" "Show Titles" "Show All" "Select One" "Quit"; do
  case $option in
    "Show Pages")
      showPages
      ;;
    "Show Meta")
      for url in $xml_data; do
        # Extract text from <loc> tags
        text=$(echo "$url" | grep -oP '<loc>\K[^<]*')
        getMetaTags "$text" "meta"
      done
      ;;
    "Show Titles")
      for url in $xml_data; do
        # Extract text from <loc> tags
        text=$(echo "$url" | grep -oP '<loc>\K[^<]*')
        getMetaTags "$text" "titles"
      done
      ;;
    "Show All")
      for url in $xml_data; do
        # Extract text from <loc> tags
        text=$(echo "$url" | grep -oP '<loc>\K[^<]*')
        getMetaTags "$text"
      done
      ;;
    "Select One")
      selectOne
      ;;
    "Quit")
      break
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done

