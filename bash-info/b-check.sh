if ls *.zip 1> /dev/null 2>&1; then
  # Loop through the zip files and unzip them
  for zip_file in *.zip; do
    # Unzip the file into the same directory
    unzip "$zip_file"
  done
  rm *.zip
else
  echo "No zip files found in the directory."
fi
