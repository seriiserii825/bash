#! /bin/bash
args=("$@")

if [ ! $# -gt 0 ]; then
    echo "${tmagenta}Set one ore more file name to optimize${treset}"
    exit 1
fi

for i in "${args[@]}"; do
  file_path=$(find -name "$i.jpg" -type f);
  if [ $file_path ]; then
    echo "${tgreen}Optimizing $file_path${treset}";
    jpegoptim --strip-all --all-progressive -ptm 80 $file_path;
  else
    echo "${tred}File $i.jpg not found${treset}";
  fi
done


