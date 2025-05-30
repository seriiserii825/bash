#! /bin/bash

function toFile(){
  read -p "${tgreen}Enter file name: ${treset}" file_name
  clipboard=$(xclip -o -selection clipboard)
  echo $clipboard > $file_name
  bat $file_name
}

function fromFile(){
  file_path=$( fzf )
  abs_path=$( realpath $file_path )
  echo "File path is: $file_path"
  COLUMNS=1
  select action in "${tmagenta}Delete${treset}" "${tmagenta}DeleteAllWithPattern${treset}" "${tmagenta}DeleteAllExceptThis${treset}" "${tmagenta}DeleteAllExceptPattern${treset}" "${tgreen}Rename${treset}" "${tgreen}Read${treset}" "${tblue}CopyName${treset}" "${tblue}CopyPath${treset}" "${tblue}CopyAbsPath${treset}" "${tblue}CopyToDownloads${treset}" "${tblue}FileToBuffer${treset}" "${tblue}BufferToFile${treset}" "${tgreen}Execute${treset}" "${tblue}OpenInBrowser${treset}" "${tblue}Multiply${treset}" "${tblue}Find words${treset}" Quit; do
    case $action in
      "${tmagenta}Delete${treset}")
        rm $file_path
        echo "${tgreen}File $file_path was deleted${treset}"
        ls -la
        break
				;;
      "${tmagenta}DeleteAllExceptThis${treset}")
        find . -maxdepth 1 -type f -not -name "$file" -delete
        echo "${tgreen}All files except $file were deleted${treset}"
        ls -la
        break
				;;
      "${tmagenta}DeleteAllWithPattern${treset}")
        read -p "Enter pattern to keep: " pattern
        find . -maxdepth 1 -type f -name "*$pattern*" -exec rm {} +
        echo "${tgreen}All files with $pattern were deleted${treset}"
        ls -la
        break
				;;
      "${tmagenta}DeleteAllExceptPattern${treset}")
        read -p "Enter pattern to keep: " pattern
        find . -maxdepth 1 -type f ! -name "*$pattern*" -exec rm {} +
        echo "${tgreen}All files except $pattern were deleted${treset}"
        ls -la
        break
				;;
      "${tgreen}Rename${treset}")
        read -p "Enter new file name: " new_file_name
        echo "file path is: $file_path"
        dir_path=$(dirname $file_path)
        echo "dir path is: $dir_path"
        mv $file_path $dir_path/$new_file_name
        echo "${tgreen}File $file_path was renamed to $dir_path/$new_file_name${treset}"
        break
				;;
      "${tgreen}Read${treset}")
        bat $file_path
        break
				;;
      "${tblue}CopyName${treset}")
        echo $file_path | awk 'BEGIN{FS="/"}{print $NF}' | tr -d '\n' | xsel -b -i
        file_name=$( echo $file_path | awk 'BEGIN{FS="/"}{print $NF}' | tr -d '\n')
        echo "${tgreen}${file_name} was copied to clipboard${treset}"
        break
				;;
      "${tblue}CopyPath${treset}")
        echo $file_path | tr -d '\n' | xsel -b -i
        file_path=$( echo $file_path | tr -d '\n' )
        echo "${tgreen}Path ${file_path} was copied to clipboard${treset}"
        break
				;;
      "${tblue}CopyAbsPath${treset}")
        echo $abs_path | tr -d '\n' | xsel -b -i
        abs_full_path=$( echo $abs_path | tr -d '\n' )
        echo "${tgreen}Path ${abs_full_path} was copied to clipboard${treset}"
        break
				;;
      "${tblue}CopyToDownloads${treset}")
        cp $file_path ~/Downloads
        echo "${tgreen}File ${file_path} was copied to Downloads${treset}"
        break
				;;
      "${tgreen}Execute${treset}")
        chmod +x $file_path
        echo "${tgreen}"Execute" permission was added to $file_path${treset}"
        break
				;;
      "${tblue}FileToBuffer${treset}")
        cat $file_path | tr -d '\n' | xsel -b -i
        echo "${tgreen}File $file_path was copied to clipboard${treset}"
        break
				;;
      "${tblue}BufferToFile${treset}")
        clipboard=$(xclip -o -selection clipboard)
        echo $clipboard > $file_path
        break
				;;
      "${tblue}OpenInBrowser${treset}")
        google-chrome-stable $file_path
        break
				;;
      "${tblue}Multiply${treset}")
        file_name=$( echo $file_path | awk 'BEGIN{FS="/"}{print $NF}' | tr -d '\n' )
        file_without_extension="${file_path%.*}"
        file_extension="${file_path##*.}"
        read -p "Enter how much you want to multiply the file: " multiplier
        if [ -z "$multiplier" ]; then
          echo "Multiplier is empty"
          exit 1
        fi

        for i in $( seq 1 $multiplier ); do
          cp $file_path $file_without_extension-$i.$file_extension
        done
        break
				;;
      "${tblue}Find words${treset}")
        file_name=$( echo $file_path | awk 'BEGIN{FS="/"}{print $NF}' | tr -d '\n' )
        copied_file="copy-$file_name"
        read -p "Enter 2 words to find separated by comma: " word
        word1=$( echo $word | awk 'BEGIN{FS=","}{print $1}' )
        word2=$( echo $word | awk 'BEGIN{FS=","}{print $2}' )
        awk '{print NR,$0}' $file_path > $copied_file
        # grep $word1 $file_path | grep -n $word2
        grep $word1 $copied_file | grep $word2
        rm $copied_file
        break
				;;
      Quit)
        break
        break
				;;
      *)
        echo "${tmagenta}Goodbye!${treset}"
        break
        break
				;;
    esac
  done
}

fromFile
