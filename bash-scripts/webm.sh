#! /bin/bash

#a=1
#for i in *; do
#  #get extension
#  ext="${i##*.}"
#  new_file=$(echo "$a-music" | tr -d '\n').$ext
#  mv -i -- "$i" "$new_file"
#  a=`expr $a + 1`
#done

# ls *.webm | while read NAME; do
#   ffmpeg -i "$NAME" "${NAME%.*}.mp3"
# done

# for FILE in *.webm; do
#     echo -e "Processing video '\e[32m$FILE\e[0m'";
#     ffmpeg -i "${FILE}" -vn -ab 128k -ar 44100 -y "${FILE%.webm}.mp3";
# done;

for FILE in *.wav; do
    echo -e "Processing video '\e[32m$FILE\e[0m'";
    # ffmpeg -i "${FILE}" "${FILE%.webm}.mp3"; 
    ffmpeg -i "${FILE}" -vn -ab 128k -ar 44100 -y "${FILE%.webm}.mp3";
done;
